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
PROFILE="${ANDROID_RE_OPENCODE_PROFILE:-default}"
START_LOG="${START_LOG:-${HOME}/Downloads/android-re-tools/re-avd-start.log}"

# Resolve config directory for the chosen profile
if [[ "${PROFILE}" == "default" ]]; then
	OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
else
	OPENCODE_CONFIG_DIR="$HOME/.config/opencode-${PROFILE}"
fi

# Focus the android workspace in niri — window rule by title "^android-re" places it correctly
if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
	NIRI_WS_REF="$(niri msg workspaces 2>/dev/null | sed -n 's/.*"\([^"]*android[^"]*\)".*/\1/p' | head -n1)"
	if [[ -n "${NIRI_WS_REF}" ]]; then
		niri msg action focus-workspace "${NIRI_WS_REF}" >/dev/null 2>&1 || true
		sleep 0.3
	fi
fi

# Boot the emulator baseline if nothing is running.
# Run start in background so the OpenCode session opens immediately;
# the agent can check readiness with `re-avd.sh status` or `adb wait-for-device`.
if ! adb devices 2>/dev/null | grep -q '^emulator-'; then
	echo "No emulator running — starting Android RE baseline in background (log: ${START_LOG})"
	nohup bash "${SCRIPT_DIR}/re-avd.sh" start >"${START_LOG}" 2>&1 &
	START_PID=$!
	echo "re-avd.sh start PID: ${START_PID}"
	echo "Monitor with: tail -f ${START_LOG}"
else
	echo "Emulator already running — checking status..."
	bash "${SCRIPT_DIR}/re-avd.sh" status
fi

# Launch Ghostty with OpenCode on the android-re agent
# The niri window rule matches title "^android-re" and opens on workspace 06-android
if command -v ghostty >/dev/null 2>&1; then
	title="android-re"
	if [[ "${PROFILE}" != "default" ]]; then
		title="android-re (${PROFILE})"
	fi

	OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR}" \
		exec ghostty --title="${title}" -e opencode --agent android-re "$@"
else
	# Fallback: run directly in current terminal
	OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR}" \
		exec opencode --agent android-re "$@"
fi
