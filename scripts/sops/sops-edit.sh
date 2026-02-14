#!/usr/bin/env nix-shell
#!nix-shell -i bash -p sops
# shellcheck shell=bash
# sops-edit.sh - Edit secrets with SOPS using RAM-backed tmpfs for security.
set -euo pipefail

export TMPDIR=/dev/shm
export EDITOR="code --wait"
exec sops secrets/secrets.yaml
