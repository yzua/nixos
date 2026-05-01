#!/usr/bin/env bash
# Tmux session layout and terminal management for web RE.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/web-re/_helpers.sh

TMUX_SESSION="${TMUX_SESSION:-web-re}"
TMUX_SHELL_WINDOW="${TMUX_SHELL_WINDOW:-shell}"
TMUX_MITM_WINDOW="${TMUX_MITM_WINDOW:-mitm}"
TMUX_PROXY_WINDOW="${TMUX_PROXY_WINDOW:-proxy}"
TMUX_LOG_WINDOW="${TMUX_LOG_WINDOW:-logs}"
TMUX_RECON_WINDOW="${TMUX_RECON_WINDOW:-recon}"
RE_WORKSPACE="${RE_WORKSPACE:-7}"

focus_re_workspace() {
	local workspace_ref
	if ! command -v niri >/dev/null 2>&1; then
		return 0
	fi
	workspace_ref="$(resolve_niri_web_re_workspace "${RE_WORKSPACE}")"

	if ! niri msg action focus-workspace "${workspace_ref}" >/dev/null 2>&1; then
		log_warning "failed to focus Niri workspace ${workspace_ref}"
	fi
}

open_re_terminal() {
	local title="web-re"

	if ! command -v ghostty >/dev/null 2>&1; then
		return 0
	fi

	if command -v niri >/dev/null 2>&1 && niri msg version >/dev/null 2>&1; then
		focus_re_workspace
		if niri msg action spawn -- ghostty --title="${title}" -e "${SCRIPT_DIR}/web-re.sh" attach >/dev/null 2>&1; then
			return 0
		fi
		log_warning "failed to spawn Ghostty for tmux session ${TMUX_SESSION} through niri"
	fi

	if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
		nohup ghostty --title="${title}" -e "${SCRIPT_DIR}/web-re.sh" attach >/dev/null 2>&1 &
		log_success "opened Ghostty attached to tmux session ${TMUX_SESSION}"
	else
		log_warning "Ghostty launch skipped because no GUI display variables were present"
	fi
}

attach_tmux() {
	printf '\033]0;web-re\007'
	exec tmux attach-session -t "${TMUX_SESSION}"
}

ensure_re_tmux() {
	need_cmd tmux
	tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true
	tmux new-session -d -s "${TMUX_SESSION}" -n "${TMUX_SHELL_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_MITM_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_PROXY_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_LOG_WINDOW}" -c "${REPO_ROOT}"
	tmux new-window -d -t "${TMUX_SESSION}:" -n "${TMUX_RECON_WINDOW}" -c "${REPO_ROOT}"
	tmux set-option -t "${TMUX_SESSION}" -g history-limit 100000
	tmux set-option -t "${TMUX_SESSION}" -g mouse on
	tmux setw -t "${TMUX_SESSION}" -g mode-keys vi

	# Shell pane — session header
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" 'clear' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" "printf 'Web RE session: %s\n' '${TMUX_SESSION}'" Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" 'printf "Useful commands: curl -s http://localhost:9222/json | jq .[].url | nuclei -u URL | sqlmap -u URL\n"' Enter

	# Logs pane — tail Chrome debug logs if available
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_LOG_WINDOW}" 'clear' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_LOG_WINDOW}" 'printf "=== Web RE Logs ===\nWaiting for log input...\n"' Enter

	# Recon pane — ready for recon commands
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_RECON_WINDOW}" 'clear' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_RECON_WINDOW}" 'printf "=== Web RE Recon ===\nCommands: nmap -sV -sC TARGET | nuclei -u URL | ffuf -u URL/FUZZ -w /path/wordlist | whatweb URL\n"' Enter

	# Proxy pane — ready for proxy tools
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_PROXY_WINDOW}" 'clear' Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_PROXY_WINDOW}" 'printf "=== Web RE Proxy ===\nChrome proxy: port 9222 (CDP) | mitmproxy: port 8084\nCommands: curl -x http://127.0.0.1:8084 URL | http_proxy=http://127.0.0.1:8084 https_proxy=http://127.0.0.1:8084 COMMAND\n"' Enter

	tmux select-window -t "${TMUX_SESSION}:${TMUX_SHELL_WINDOW}" >/dev/null 2>&1 || true
}
