#!/usr/bin/env bash
# Launch an OpenCode Android RE session with emulator baseline.
# Called by oc*are wrappers (ocare, ocglmare, ocgemare, etc.)
# Env vars set by the Nix wrapper:
#   ANDROID_RE_OPENCODE_PROFILE   - opencode profile name (default, glm, gemini, gpt, openrouter, sonnet, zen)
#
# The android-re agent's system prompt already contains the full RE prompt bundle
# (AGENTS.md, WORKFLOW.md, TOOLS.md, TROUBLESHOOTING.md, README.md) injected at Nix eval time.
# No need to pass them again via --prompt.
#
# If no emulator is running, `re-avd.sh start` is launched in the background so the
# agent session opens immediately instead of blocking on the full boot chain.
# The agent can monitor progress with `re-avd.sh status` or `adb wait-for-device`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROFILE="${ANDROID_RE_OPENCODE_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/android-re-tools/re-avd-start.log}"

# Resolve config directory for the chosen profile
if [[ "${PROFILE}" == "default" ]]; then
	BASE_OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
else
	BASE_OPENCODE_CONFIG_DIR="$HOME/.config/opencode-${PROFILE}"
fi

# Focus the android workspace in niri — window rule by title "^android-re" places it correctly
# shellcheck source=scripts/ai/android-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
NIRI_WS_REF="$(resolve_niri_android_workspace)"
if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
	if [[ -n "${NIRI_WS_REF}" ]]; then
		niri msg action focus-workspace "${NIRI_WS_REF}" >/dev/null 2>&1 || true
		sleep 0.3
	fi
fi

# Boot the emulator baseline if nothing is running.
# Run start in background so the OpenCode session opens immediately;
# the agent can check readiness with `re-avd.sh status` or `adb wait-for-device`.
if ! emulator_online; then
	echo "No emulator running — starting Android RE baseline in background (log: ${START_LOG})"
	nohup bash "${SCRIPT_DIR}/re-avd.sh" start >"${START_LOG}" 2>&1 &
	START_PID=$!
	echo "re-avd.sh start PID: ${START_PID}"
	echo "Monitor with: tail -f ${START_LOG}"
else
	echo "Emulator already running — checking status..."
	bash "${SCRIPT_DIR}/re-avd.sh" status
fi

# OpenCode TUI currently rejects custom agents passed via top-level --agent in this flow.
# Use a runtime config overlay that pins default_agent=android-re instead.
RUNTIME_CONFIG_PARENT="${XDG_CACHE_HOME:-${HOME}/.cache}/opencode-android-re"
mkdir -p "${RUNTIME_CONFIG_PARENT}"
RUNTIME_CONFIG_DIR="$(mktemp -d "${RUNTIME_CONFIG_PARENT}/${PROFILE}.XXXXXX")"

if [[ -d "${BASE_OPENCODE_CONFIG_DIR}" ]]; then
	# Preserve full profile config (tui theme, commands, plugins, etc.) in the runtime overlay.
	cp -a "${BASE_OPENCODE_CONFIG_DIR}/." "${RUNTIME_CONFIG_DIR}/"
fi

if [[ -f "${RUNTIME_CONFIG_DIR}/opencode.json" ]] && command -v jq >/dev/null 2>&1; then
	jq '.default_agent = "android-re"' "${RUNTIME_CONFIG_DIR}/opencode.json" >"${RUNTIME_CONFIG_DIR}/opencode.json.tmp"
	mv -f "${RUNTIME_CONFIG_DIR}/opencode.json.tmp" "${RUNTIME_CONFIG_DIR}/opencode.json"
fi

if command -v ghostty >/dev/null 2>&1; then
	title="android-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="android-re (${PROFILE})"
	fi

	OPENCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec ghostty --title="${title}" -e opencode "$@"
else
	# Fallback: run directly in current terminal
	OPENCODE_CONFIG_DIR="${RUNTIME_CONFIG_DIR}" \
		exec opencode "$@"
fi
