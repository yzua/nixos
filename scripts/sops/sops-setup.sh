#!/usr/bin/env bash
set -euo pipefail

# SOPS-Nix setup script
# This script helps set up age keys for sops-nix

KEY_FILE="$HOME/.config/sops/age/keys.txt"

echo "=== SOPS-Nix Age Key Setup ==="
echo ""

# Create directory if it doesn't exist
mkdir -p "$(dirname "$KEY_FILE")"

if [[ -f "$KEY_FILE" ]]; then
    echo "Age key file already exists at: $KEY_FILE"
    echo "Current public key:"
    nix shell nixpkgs#age -c age-keygen -y "$KEY_FILE"
    echo ""
    echo "If you want to generate a new key, backup the current file and remove it first."
else
    echo "Generating new age key..."
    nix shell nixpkgs#age -c age-keygen -o "$KEY_FILE"
    echo ""
    echo "New age key generated at: $KEY_FILE"
    echo "Public key:"
    nix shell nixpkgs#age -c age-keygen -y "$KEY_FILE"
    echo ""
    echo "⚠️  IMPORTANT: Add the public key to your .sops.yaml file"
fi

echo ""
echo "To generate key from existing SSH key:"
echo "nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/private > $KEY_FILE"
echo ""
echo "To get public key:"
echo "nix shell nixpkgs#age -c age-keygen -y $KEY_FILE"