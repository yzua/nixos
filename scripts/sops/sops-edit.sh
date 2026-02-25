#!/usr/bin/env nix-shell
#!nix-shell -i bash -p sops
# shellcheck shell=bash
# sops-edit.sh - Edit secrets with SOPS using RAM-backed tmpfs for security.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export TMPDIR=/dev/shm
export EDITOR="${EDITOR:-code --wait}"
exec sops "${REPO_DIR}/secrets/secrets.yaml"
