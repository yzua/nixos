#!/usr/bin/env bash
# pre-commit-hook.sh - Prevent committing broken NixOS config.
# Install: just install-hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

DEADNIX_EXCLUDES=(
	./home-manager/modules/terminal/zellij/layouts.nix
)

print_info "Pre-commit: validating NixOS config..."

# Fast checks only — full build is too slow for a hook.
# Escalation: modules (fastest) → lint → format check → flake check.

print_info "Checking module imports..."
bash ./scripts/build/modules-check.sh

print_info "Linting..."
statix check --ignore '.git/**'
deadnix --fail --exclude "${DEADNIX_EXCLUDES[@]}" .

print_info "Checking formatting..."
nix fmt -- --fail-on-change . 2>/dev/null || {
	print_error "Formatting check failed. Run 'just format' first."
	exit 1
}

print_info "Evaluating flake..."
nix flake check --no-build path:.

print_success "Pre-commit checks passed!"
