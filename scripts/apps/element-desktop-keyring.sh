#!/usr/bin/env bash
set -euo pipefail

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/element-desktop-url-handler.log"
main_log_file="${XDG_CACHE_HOME:-$HOME/.cache}/element-desktop-main.log"
{
  printf '%s ' "$(date --iso-8601=seconds)"
  printf '%q ' "$@"
  printf '\n'
} >> "$log_file"

export ELECTRON_ENABLE_LOGGING=1
exec __ELEMENT_DESKTOP_BIN__ --password-store=gnome-libsecret "$@" >> "$main_log_file" 2>&1
