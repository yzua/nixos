#!/usr/bin/env bash
# Extract inline pkgs.writeShellScript/writeShellScriptBin bodies from .nix files
# and lint them with shellcheck.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
AWK_UTILS="${SCRIPT_DIR}/../lib/awk-utils.awk"
AWK_EXTRACT="${SCRIPT_DIR}/../lib/extract-nix-shell.awk"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

awk_script="$tmp_dir/extract.awk"
{
  cat "$AWK_UTILS"
  cat "$AWK_EXTRACT"
} > "$awk_script"

mapfile -t extracted_scripts < <(
	rg --files -g '*.nix' . | xargs -d '\n' -P4 -I{} awk -v tmpdir="$tmp_dir" -v src="{}" -f "$awk_script" "{}"
)

if ((${#extracted_scripts[@]} == 0)); then
	print_info "No inline writeShellScript blocks found."
	exit 0
fi

shellcheck_bin="$(command -v shellcheck 2>/dev/null || echo "nix run nixpkgs#shellcheck --")"
# shellcheck disable=SC2086
printf '%s\0' "${extracted_scripts[@]}" | xargs -0 -r ${shellcheck_bin} \
	-s bash \
	-S error \
	-e SC1114,SC1128,SC2239
print_success "Inline Nix shell scripts passed! (${#extracted_scripts[@]} blocks)"
