#!/usr/bin/env bash
# Shared helper functions for Android RE scripts.
# Source this file after sourcing logging.sh.

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/require.sh"

# Resolve the niri workspace reference containing "android" in its name.
# Prints the workspace ref (or the fallback if niri is unavailable/no match).
resolve_niri_android_workspace() {
	local fallback="${1:-}"
	if ! command -v niri >/dev/null 2>&1; then
		printf '%s\n' "${fallback}"
		return 0
	fi
	local ref
	ref="$(niri msg workspaces 2>/dev/null | sed -n 's/.*"\([^"]*android[^"]*\)".*/\1/p' | head -n1)"
	if [[ -n "${ref}" ]]; then
		printf '%s\n' "${ref}"
	else
		printf '%s\n' "${fallback}"
	fi
}
