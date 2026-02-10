#!/usr/bin/env bash
# setup-keys.sh - Setup SSH and GPG keys from SOPS on a new machine

set -euo pipefail

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT INT TERM

echo "=== Setting Up SSH and GPG Keys from SOPS ==="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  Warning: $1${NC}"
}

log_info() {
    echo "ℹ️  $1"
}

# Validate key integrity
validate_ssh_key() {
    local key_file="$1"
    if ! ssh-keygen -l -f "$key_file" >/dev/null 2>&1; then
        log_error "Invalid SSH key: $key_file"
        return 1
    fi
    return 0
}

validate_gpg_key() {
    local key_file="$1"
    if ! gpg --import-options show-only --import "$key_file" >/dev/null 2>&1; then
        log_error "Invalid GPG key: $key_file"
        return 1
    fi
    return 0
}

# Check if SOPS is available
if ! command -v sops &> /dev/null; then
    log_error "SOPS is not installed. Please install sops-nix first."
    exit 1
fi

# Check if age key exists and is valid
if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
    log_error "Age key not found. Please run 'just sops-setup' first."
    exit 1
elif ! nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt &> /dev/null; then
    log_error "Age key file is invalid or corrupt. Please ensure it contains a valid age private key."
    exit 1
fi

# Check if secrets file exists
if [[ ! -f secrets/secrets.yaml ]]; then
    log_error "secrets/secrets.yaml not found. Please copy it from your main machine."
    exit 1
fi

# Check if we can decrypt secrets
if ! just sops-view >/dev/null 2>&1; then
    log_error "Cannot decrypt secrets. Check your age key and secrets file."
    exit 1
fi

log_success "Prerequisites check passed!"
echo ""

# Create SSH directory with secure permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Extract SSH keys with enhanced security
log_info "Setting up SSH keys..."

# Backup existing SSH keys securely
SSH_BACKUP_DIR="$TEMP_DIR/ssh_backup"
mkdir -p "$SSH_BACKUP_DIR"

if [[ -f ~/.ssh/id_ed25519 ]]; then
    cp ~/.ssh/id_ed25519 "$SSH_BACKUP_DIR/"
    log_info "Backed up existing SSH private key"
fi
if [[ -f ~/.ssh/id_ed25519.pub ]]; then
    cp ~/.ssh/id_ed25519.pub "$SSH_BACKUP_DIR/"
    log_info "Backed up existing SSH public key"
fi

# Extract SSH private key securely
SSH_PRIVATE="$TEMP_DIR/ssh_private"
if just sops-view | grep -A 50 "ssh_private_key:" | tail -n +2 | sed 's/^    //' > "$SSH_PRIVATE" && [[ -s "$SSH_PRIVATE" ]]; then
    if validate_ssh_key "$SSH_PRIVATE"; then
        mv "$SSH_PRIVATE" ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        log_success "SSH private key extracted and configured"
    else
        rm -f "$SSH_PRIVATE"
        log_error "Extracted SSH private key is invalid"
        # Restore backup if validation failed
        if [[ -f "$SSH_BACKUP_DIR/id_ed25519" ]]; then
            mv "$SSH_BACKUP_DIR/id_ed25519" ~/.ssh/
        fi
        exit 1
    fi
else
    rm -f "$SSH_PRIVATE"
    log_error "Failed to extract SSH private key from secrets"
    # Restore backup if extraction failed
    if [[ -f "$SSH_BACKUP_DIR/id_ed25519" ]]; then
        mv "$SSH_BACKUP_DIR/id_ed25519" ~/.ssh/
    fi
    exit 1
fi

# Extract SSH public key securely
SSH_PUBLIC="$TEMP_DIR/ssh_public"
if just sops-view | grep "ssh_public_key:" | cut -d' ' -f2- > "$SSH_PUBLIC" && [[ -s "$SSH_PUBLIC" ]]; then
    mv "$SSH_PUBLIC" ~/.ssh/id_ed25519.pub
    chmod 644 ~/.ssh/id_ed25519.pub
    log_success "SSH public key extracted and configured"
else
    log_error "Failed to extract SSH public key from secrets"
    # Restore backup if extraction failed
    if [[ -f "$SSH_BACKUP_DIR/id_ed25519.pub" ]]; then
        mv "$SSH_BACKUP_DIR/id_ed25519.pub" ~/.ssh/
    fi
    exit 1
fi

# Extract and import GPG key securely
log_info "Setting up GPG key..."

# Extract GPG private key to secure temporary location
GPG_KEY_FILE="$TEMP_DIR/gpg_key.asc"
if just sops-view | grep -A 50 "gpg_private_key:" | tail -n +2 | sed 's/^    //' > "$GPG_KEY_FILE" && [[ -s "$GPG_KEY_FILE" ]]; then
    if validate_gpg_key "$GPG_KEY_FILE"; then
        # Import GPG key with secure options
        if gpg --import-options import-show --import "$GPG_KEY_FILE" >/dev/null 2>&1; then
            gpg --import "$GPG_KEY_FILE"
            log_success "GPG private key extracted and imported"
        else
            rm -f "$GPG_KEY_FILE"
            log_error "GPG key import failed - key may be corrupted"
            exit 1
        fi
    else
        rm -f "$GPG_KEY_FILE"
        log_error "Extracted GPG key is invalid"
        exit 1
    fi
else
    rm -f "$GPG_KEY_FILE"
    log_error "Failed to extract GPG private key from secrets"
    exit 1
fi

# Get GPG key ID with validation
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -1 | cut -d'/' -f2 | cut -d' ' -f1)
if [[ -n "$GPG_KEY_ID" ]]; then
    log_success "GPG Key ID: $GPG_KEY_ID"
else
    log_error "Failed to get GPG key ID"
    exit 1
fi

# Configure Git
echo ""
echo "⚙️  Configuring Git..."

# Extract Git config from SSH public key (fallback if not in secrets)
GIT_EMAIL=$(just sops-view | grep "ssh_public_key:" | awk '{print $NF}')
GIT_NAME=$(echo "$GIT_EMAIL" | cut -d'@' -f1)

# If we have git_user_name and git_user_email in secrets, use those instead
if just sops-view | grep -q git_user_name; then
    GIT_NAME=$(just sops-view | grep git_user_name | cut -d' ' -f2 | tr -d '"')
fi

if just sops-view | grep -q git_user_email; then
    GIT_EMAIL=$(just sops-view | grep git_user_email | cut -d' ' -f2 | tr -d '"')
fi

if git config --global user.name "$GIT_NAME" 2>/dev/null && \
   git config --global user.email "$GIT_EMAIL" 2>/dev/null && \
   git config --global user.signingkey "$GPG_KEY_ID" 2>/dev/null && \
   git config --global commit.gpgsign true 2>/dev/null; then
    echo "✔ Git configured with:"
    echo "   Name: $GIT_NAME"
    echo "   Email: $GIT_EMAIL"
    echo "   Signing Key: $GPG_KEY_ID"
else
    echo "⚠️  Warning: Could not configure Git (read-only filesystem). Please configure manually:"
    echo "   git config --global user.name \"$GIT_NAME\""
    echo "   git config --global user.email \"$GIT_EMAIL\""
    echo "   git config --global user.signingkey \"$GPG_KEY_ID\""
    echo "   git config --global commit.gpgsign true"
fi

# Start SSH agent and add key
echo ""
echo "🚀 Starting SSH agent..."
if eval "$(ssh-agent -s)" 2>/dev/null; then
    ssh-add ~/.ssh/id_ed25519
    echo "✔ SSH agent started and key added"
else
    echo "⚠️  Warning: Could not start SSH agent"
fi

# Test SSH connection (optional - PRIVACY: skips on monitored networks)
echo ""
echo "🧪 Test SSH connection to GitHub? (y/N)"
read -r -n 1 response
echo ""
if [[ "$response" =~ ^[Yy]$ ]]; then
    if ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"; then
        echo "✔ SSH connection to GitHub successful!"
    else
        echo "⚠️  Warning: SSH connection test failed. You may need to add the key to your GitHub account."
    fi
else
    echo "⊘ Skipping GitHub connectivity test (OPSEC: prevents timing correlation)"
fi

# Show GPG public key
echo ""
echo "🔑 GPG Public Key (add this to GitHub):"
echo "========================================"
gpg --armor --export "$GPG_KEY_ID"
echo "========================================"

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Add the GPG public key above to your GitHub account"
echo "2. Test SSH: ssh -T git@github.com"
echo "3. Test GPG: echo 'test' | gpg --clearsign"
echo "4. Test signed commit: git commit --allow-empty -m 'Test signed commit'"
echo ""
echo "Your keys are now ready to use! 🔑✨"