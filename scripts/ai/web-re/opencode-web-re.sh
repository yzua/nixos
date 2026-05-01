#!/usr/bin/env bash
# Launch an OpenCode web RE session with Chrome baseline.
# Called by oc*wre wrappers.
# Env vars set by the Nix wrapper:
#   WEB_RE_OPENCODE_PROFILE   - opencode profile name (default, glm, gemini, gpt, openrouter, sonnet, zen)
#
# The web-re agent's system prompt already contains the full RE prompt bundle
# (AGENTS.md, WORKFLOW.md, TOOLS.md, TROUBLESHOOTING.md, README.md) injected at Nix eval time.
# No need to pass them again via --prompt.
#
# If Chrome is not running with remote debugging, it is launched in the background so the
# agent session opens immediately instead of blocking.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROFILE="${WEB_RE_OPENCODE_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/web-re-tools/web-re-start.log}"

# Resolve config directory for the chosen profile
if [[ "${PROFILE}" == "default" ]]; then
	BASE_OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
else
	BASE_OPENCODE_CONFIG_DIR="$HOME/.config/opencode-${PROFILE}"
fi

# Focus the web-re workspace in niri -- window rule by title "^web-re" places it correctly
# shellcheck source=scripts/lib/logging.sh
source "${REPO_ROOT}/scripts/lib/logging.sh"
# shellcheck source=scripts/ai/web-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
# shellcheck source=scripts/ai/web-re/_tmux.sh
source "${SCRIPT_DIR}/_tmux.sh"
# shellcheck source=scripts/ai/web-re/_chrome.sh
source "${SCRIPT_DIR}/_chrome.sh"
# shellcheck source=scripts/ai/web-re/_mitm.sh
source "${SCRIPT_DIR}/_mitm.sh"
focus_re_workspace
sleep 0.3

# Create tmux session for mitm, proxy, logs, and recon panes
ensure_re_tmux

# Start mitmproxy in the mitm tmux pane (non-fatal)
if ! mitm_start; then
	echo "mitmproxy setup skipped — tmux session still available"
fi

# Start Chrome with remote debugging if nothing is running.
if ! chrome_running; then
	echo "Chrome not running with remote debugging -- starting web RE baseline in background (log: ${START_LOG})"
	mkdir -p "$(dirname "${START_LOG}")"
	chrome_start "$@"
else
	echo "Chrome already running -- checking status..."
	chrome_status
fi

# OpenCode TUI currently rejects custom agents passed via top-level --agent in this flow.
# Use a runtime config overlay that pins default_agent=web-re instead.
RUNTIME_CONFIG_PARENT="${XDG_CACHE_HOME:-${HOME}/.cache}/opencode-web-re"
mkdir -p "${RUNTIME_CONFIG_PARENT}"
RUNTIME_CONFIG_DIR="$(mktemp -d "${RUNTIME_CONFIG_PARENT}/${PROFILE}.XXXXXX")"

if [[ -d "${BASE_OPENCODE_CONFIG_DIR}" ]]; then
	# Preserve full profile config (tui theme, commands, plugins, etc.) in the runtime overlay.
	cp -a "${BASE_OPENCODE_CONFIG_DIR}/." "${RUNTIME_CONFIG_DIR}/"
fi

if [[ -f "${RUNTIME_CONFIG_DIR}/opencode.json" ]] && command -v jq >/dev/null 2>&1; then
	# Pin default agent to web-re
	jq '.default_agent = "web-re"' "${RUNTIME_CONFIG_DIR}/opencode.json" >"${RUNTIME_CONFIG_DIR}/opencode.json.tmp"
	mv -f "${RUNTIME_CONFIG_DIR}/opencode.json.tmp" "${RUNTIME_CONFIG_DIR}/opencode.json"

	# Merge web-re-specific MCP servers into runtime config.
	# These are NOT in the shared profile -- they only appear in the web-re overlay.
	WEB_RE_MCP_FILE="$HOME/.config/opencode/web-re-mcp-servers.json"
	if [[ -f "${WEB_RE_MCP_FILE}" ]]; then
		jq --slurpfile wrmcp "${WEB_RE_MCP_FILE}" \
			'.mcp += $wrmcp[0]' \
			"${RUNTIME_CONFIG_DIR}/opencode.json" >"${RUNTIME_CONFIG_DIR}/opencode.json.tmp"
		mv -f "${RUNTIME_CONFIG_DIR}/opencode.json.tmp" "${RUNTIME_CONFIG_DIR}/opencode.json"
	fi
fi

# Spawn a separate ghostty terminal for the tmux session (non-blocking).
open_re_terminal

if command -v ghostty >/dev/null 2>&1; then
	title="web-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="web-re (${PROFILE})"
	fi

	OPENCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec ghostty --title="${title}" -e opencode "$@"
else
	# Fallback: run directly in current terminal
	OPENCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec opencode "$@"
fi
