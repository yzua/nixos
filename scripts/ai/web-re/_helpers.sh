#!/usr/bin/env bash
# Shared helper functions for web RE scripts.
# Source this file after sourcing logging.sh.

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/require.sh"

CHROME_DEBUG_PORT="${CHROME_DEBUG_PORT:-9222}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-${HOME}/.cache/web-re-tools/chrome-profile}"

# Check whether Chrome with remote debugging is running.
chrome_running() {
	port_in_use "${CHROME_DEBUG_PORT}"
}

# Check whether a TCP port has an active listener on the host.
port_in_use() {
	local port="$1"
	command -v ss >/dev/null 2>&1 && ss -ltnH "( sport = :${port} )" | grep -q .
}

# Resolve the niri workspace reference containing "web-re" in its name.
# Prints the workspace ref (or the fallback if niri is unavailable/no match).
resolve_niri_web_re_workspace() {
	local fallback="${1:-}"
	if ! command -v niri >/dev/null 2>&1; then
		printf '%s\n' "${fallback}"
		return 0
	fi
	local ref
	ref="$(niri msg workspaces 2>/dev/null | sed -n 's/.*"\([^"]*web-re[^"]*\)".*/\1/p' | head -n1)"
	if [[ -n "${ref}" ]]; then
		printf '%s\n' "${ref}"
	else
		printf '%s\n' "${fallback}"
	fi
}
