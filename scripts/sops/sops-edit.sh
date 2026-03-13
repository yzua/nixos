#!/usr/bin/env nix-shell
#!nix-shell -i bash -p sops
# shellcheck shell=bash
# sops-edit.sh - Edit secrets with SOPS using RAM-backed tmpfs for security.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export TMPDIR=/dev/shm

DEFAULT_EDITOR="${SCRIPT_DIR}/editor-code-wait.sh"
export SOPS_EDITOR="${SOPS_EDITOR:-${DEFAULT_EDITOR}}"
exec sops "${REPO_DIR}/secrets/secrets.yaml"
