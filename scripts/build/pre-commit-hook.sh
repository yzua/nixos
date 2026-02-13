#!/usr/bin/env bash
# pre-commit-hook.sh - Prevent committing broken NixOS config.
# Install: just install-hooks

set -euo pipefail

echo "🔍 Pre-commit: validating NixOS config..."

# Fast checks only — full build is too slow for a hook.
# Escalation: modules (fastest) → lint → format check → flake check.

echo "  ➤ Checking module imports..."
bash ./scripts/build/modules-check.sh

echo "  ➤ Linting..."
nix run nixpkgs#statix -- check --ignore '.git/**'
nix run nixpkgs#deadnix -- --fail --exclude ./home-manager/modules/terminal/zellij.nix .

echo "  ➤ Checking formatting..."
nix fmt -- --fail-on-change --no-cache . 2>/dev/null || {
	echo "✗ Formatting check failed. Run 'just format' first."
	exit 1
}

echo "  ➤ Evaluating flake..."
nix flake check --no-build

echo "✔ Pre-commit checks passed!"
