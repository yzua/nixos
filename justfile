set shell := ["/usr/bin/env", "bash", "-c"]
set quiet

JUST := "just -u -f " + justfile()
header := "Available tasks:\n"

_default:
    @{{JUST}} --list-heading "{{header}}" --list

# Format all .nix files
format:
    @echo -e "\n➤ Formatting Nix files"
    @nix fmt
    @echo "✔ Formatting passed!"

# Lint all .nix files and bash scripts
lint:
    @echo -e "\n➤ Linting Nix files…"
    @\time -f "⏱ Completed in %E" nix run nixpkgs#statix -- check --ignore '.git/**'
    @echo "✔ Nix linting passed!"
    @{{JUST}} dead
    @echo -e "\n➤ Checking Bash scripts…"
    @\time -f "⏱ Completed in %E" find . -name "*.sh" -not -path "./.git/*" -exec nix run nixpkgs#shellcheck -- {} +
    @echo "✔ ShellCheck passed!"

# Scan for unused code in .nix files
dead:
    @echo -e "\n➤ Checking for dead Nix code…"
    @\time -f "⏱ Completed in %E" nix run nixpkgs#deadnix -- --fail --exclude ./home-manager/modules/terminal/zellij.nix .
    @echo "✔ Deadnix check passed!"

# Run nix flake check
check:
    @echo -e "\n➤ Running nix flake check…"
    @\time -f "⏱ Completed in %E" nix flake check --no-build
    @echo "✔ Flake check passed!"

# Check all missing imports
modules:
    @echo -e "\n➤ Checking modules"
    @\time -f "⏱ Completed in %E" bash ./scripts/build/modules-check.sh

# Switch Home-Manager generation
home:
    @echo -e "\n➤ Switching Home-Manager…"
    nh home switch '.?submodules=1'

# Switch NixOS generation
nixos:
    @echo -e "\n➤ Rebuilding NixOS…"
    nh os switch .

# All of the above, in order
all:
    @echo -e "\n➤ Running full pipeline…"
    {{JUST}} modules
    {{JUST}} lint
    {{JUST}} format
    {{JUST}} check
    {{JUST}} nixos
    {{JUST}} home
    @echo -e "✔ All done!"

# Generate system health report
report mode="full":
    sudo system-report {{mode}}

# View latest system report
report-view type="full":
    system-report {{ if type == "errors" { "view-errors" } else { "view" } }}

# Show what changed between current and previous NixOS generation
diff:
    @echo -e "\n➤ Diffing NixOS generations…"
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)

# Update all flake inputs
update:
	nix flake update

# Clean up build artifacts and caches
clean:
	@echo -e "\n➤ Cleaning up build artifacts and caches…"
	@echo "[DEL] Cleaning Nix store (1 day older)..."
	nh clean all --keep 1
	@echo "[HM] Cleaning Home Manager generations..."
	home-manager expire-generations "-1 days"
	@echo "[OPT] Optimizing Nix store..."
	nix store optimise
	@echo -e "✔ Cleanup completed!"

# Install git pre-commit hook for config validation
install-hooks:
    @cp scripts/build/pre-commit-hook.sh .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✔ Pre-commit hook installed!"

# Edit secrets with SOPS (uses RAM-backed tmpfs for security)
sops-edit:
    @echo -e "\n➤ Editing secrets with SOPS…"
    @TMPFILE=$$(mktemp /dev/shm/secrets-XXXXXX.yaml) && \
    trap 'rm -f "$$TMPFILE"' EXIT INT TERM && \
    echo "Decrypting secrets to RAM..." && \
    sops --decrypt secrets/secrets.yaml > "$$TMPFILE" && \
    echo "Opening Zed (close the tab/window when done editing)..." && \
    zeditor --wait "$$TMPFILE" && \
    echo "Encrypting secrets back..." && \
    sops --encrypt "$$TMPFILE" > secrets/secrets.yaml && \
    rm -f "$$TMPFILE" && \
    echo "✔ Encrypted and cleaned up!"

# View decrypted secrets (read-only)
sops-view:
	@echo -e "\n➤ Viewing decrypted secrets…"
	sops --decrypt secrets/secrets.yaml

# Decrypt secrets to RAM-backed file for manual editing
sops-decrypt:
	@echo -e "\n➤ Decrypting secrets to /dev/shm/secrets-decrypted.yaml…"
	sops --decrypt secrets/secrets.yaml > /dev/shm/secrets-decrypted.yaml
	@echo "Edit /dev/shm/secrets-decrypted.yaml then run: just sops-encrypt"
	@echo "⚠ File is in RAM — will be lost on reboot (this is intentional for security)"

# Encrypt file back to secrets
sops-encrypt:
	@echo -e "\n➤ Encrypting /dev/shm/secrets-decrypted.yaml to secrets/secrets.yaml…"
	sops --encrypt /dev/shm/secrets-decrypted.yaml > secrets/secrets.yaml
	@rm -f /dev/shm/secrets-decrypted.yaml
	@echo "✔ Encrypted and cleaned up!"

# Add a single secret (reads value from stdin to avoid process list exposure)
secrets-add key:
	@echo "{{key}}" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*$' || (echo "✗ Invalid key name. Use alphanumeric characters and underscores only." && exit 1)
	@read -s -p "Enter secret value for '{{key}}': " VALUE && echo "" && \
	sops --set "[\"{{key}}\"] \"$$VALUE\"" secrets/secrets.yaml && \
	echo "✔ Secret added!"

# Setup SOPS age key
sops-setup:
	@echo -e "\n➤ Setting up SOPS age key…"
	./scripts/sops/sops-setup.sh

# Setup SSH and GPG keys from SOPS
setup-keys:
	@echo -e "\n➤ Setting up SSH and GPG keys from SOPS…"
	./scripts/sops/setup-keys.sh

# Show SOPS public key
sops-key:
	@echo -e "\n➤ SOPS public key:"
	@sops --version && echo ""
	@if [ -f ~/.config/sops/age/keys.txt ]; then \
		echo "Public key:"; \
		nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt; \
	else \
		echo "No age key found. Run 'just sops-setup' to create one."; \
	fi
