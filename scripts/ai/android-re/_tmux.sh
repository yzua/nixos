#!/usr/bin/env bash
# Tmux session layout and terminal management.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/android-re/_helpers.sh

TMUX_SESSION="${TMUX_SESSION:-android-re}"
TMUX_SHELL_WINDOW="${TMUX_SHELL_WINDOW:-shell}"
TMUX_MITM_WINDOW="${TMUX_MITM_WINDOW:-mitm}"
TMUX_FRIDA_WINDOW="${TMUX_FRIDA_WINDOW:-frida}"
TMUX_LOG_WINDOW="${TMUX_LOG_WINDOW:-logs}"
TMUX_LOGCAT_WINDOW="${TMUX_LOGCAT_WINDOW:-logcat}"
RE_WORKSPACE="${RE_WORKSPACE:-6}"

focus_re_workspace() {
	local workspace_ref
	if ! command -v niri >/dev/null 2>&1; then
		return 0
	fi
	workspace_ref="$(resolve_niri_android_workspace "${RE_WORKSPACE}")"

	if ! niri msg action focus-workspace "${workspace_ref}" >/dev/null 2>&1; then
		log_warning "failed to focus Niri workspace ${workspace_ref}"
	fi
}

open_re_terminal() {
	local title="android-re"

	if ! command -v ghostty >/dev/null 2>&1; then
		return 0
	fi

	if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
		focus_re_workspace
		if niri msg action spawn -- ghostty --title="${title}" -e "${SCRIPT_DIR}/re-avd.sh" attach >/dev/null 2>&1; then
			return 0
		fi
		log_warning "failed to spawn Ghostty for tmux session ${TMUX_SESSION} through niri"
	fi

	if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
		nohup ghostty --title="${title}" -e "${SCRIPT_DIR}/re-avd.sh" attach >/dev/null 2>&1 &
		log_success "opened Ghostty attached to tmux session ${TMUX_SESSION}"
	else
		log_warning "Ghostty launch skipped because no GUI display variables were present"
	fi
}

attach_tmux() {
	printf '\033]0;android-re\007'
	exec tmux attach-session -t "${TMUX_SESSION}"
}

ensure_re_tmux() {
	need_cmd tmux
	tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true
	tmux new-session -d -s "${TMUX_SESSION}" -n "${TMUX_SHELL_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_MITM_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_FRIDA_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_LOG_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_LOGCAT_WINDOW}" -c "${REPO_ROOT}"
	tmux set-option -t "${TMUX_SESSION}" -g history-limit 100000
	tmux set-option -t "${TMUX_SESSION}" -g mouse on
	tmux setw -t "${TMUX_SESSION}" -g mode-keys vi
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" 'clear' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" "printf 'RE session: %s\n' '${TMUX_SESSION}'" Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" 'printf "Useful checks: adb devices -l | adb shell pm list packages | adb shell getprop ro.product.model\n"' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_FRIDA_WINDOW}" 'frida-ps -U || true' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_LOG_WINDOW}" "tail -f ${RUNTIME_LOG}" Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_LOGCAT_WINDOW}" 'adb wait-for-device && adb logcat -b all -v threadtime' Enter
	tmux select-window -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" >/dev/null 2>&1 || true
}
