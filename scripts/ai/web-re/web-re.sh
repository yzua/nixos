#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

trap 'log_error "command failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

RUNTIME_LOG="${RUNTIME_LOG:-${HOME}/Downloads/web-re-tools/web-re-runtime.log}"

# shellcheck source=scripts/ai/web-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
# shellcheck source=scripts/ai/web-re/_chrome.sh
source "${SCRIPT_DIR}/_chrome.sh"
# shellcheck source=scripts/ai/web-re/_mitm.sh
source "${SCRIPT_DIR}/_mitm.sh"
# shellcheck source=scripts/ai/web-re/_tmux.sh
source "${SCRIPT_DIR}/_tmux.sh"

start_re() {
	# ── Phase 1: Cleanup stale state ──
	log_info "cleaning up stale web RE state"
	kill_mitm_listeners
	chrome_stop
	log_success "cleanup complete"

	# ── Phase 2: Start Chrome with remote debugging ──
	chrome_start

	# ── Phase 3: Set up tmux session ──
	ensure_re_tmux

	# ── Phase 3b: Start mitmproxy (non-fatal) ──
	if ! mitm_start; then
		log_warning "mitmproxy setup skipped — tmux session still available"
	fi

	# ── Phase 4: Open Ghostty terminal on web-re workspace ──
	open_re_terminal

	# ── Phase 5: Final health report ──
	status_report
}

stop_re() {
	log_info "stopping web RE environment"
	chrome_stop
	mitm_stop
	tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true
	log_success "web RE environment stopped"
}

status_report() {
	echo ""
	log_info "=== Web RE Status ==="
	chrome_status
	if mitm_running; then
		log_success "mitmproxy listening on ${MITM_HOST}:${MITM_PORT}"
	else
		log_info "mitmproxy not running"
	fi
	if command -v tmux >/dev/null 2>&1 && tmux has-session -t "${TMUX_SESSION}" 2>/dev/null; then
		log_success "tmux session '${TMUX_SESSION}' active"
	else
		log_info "tmux session '${TMUX_SESSION}' not found"
	fi
	echo ""
}

doctor() {
	echo ""
	log_info "=== Web RE Doctor ==="
	check_tool google-chrome-stable || check_tool chromium
	check_tool mitmdump
	check_tool nuclei
	check_tool sqlmap
	check_tool nmap
	check_tool curl
	check_tool jq
	echo ""
}

usage() {
	cat <<'EOF'
Usage: web-re.sh <command> [args]

Env:
  CHROME_DEBUG_PORT   Chrome remote debugging port (default: 9222)
  MITM_PORT           mitmproxy listen port (default: 8084)

Commands:
  start               Start Chrome, mitmproxy, and tmux session
  stop                Stop Chrome, mitmproxy, and kill tmux session
  status              Show Chrome, mitmproxy, and tmux status
  chrome-start [URL]  Start Chrome with remote debugging
  chrome-stop         Stop Chrome
  mitm-start          Start mitmproxy
  mitm-stop           Stop mitmproxy
  doctor              Verify required tools are available
  attach              Attach to tmux session
EOF
}

main() {
	local subcmd="${1:-}"
	case "${subcmd}" in
	start)
		start_re
		;;
	stop)
		stop_re
		;;
	status)
		status_report
		;;
	chrome-start)
		chrome_start "${2:-}"
		;;
	chrome-stop)
		chrome_stop
		;;
	mitm-start)
		mitm_start
		;;
	mitm-stop)
		mitm_stop
		;;
	doctor)
		doctor
		;;
	attach)
		attach_tmux
		;;
	*)
		usage
		exit 1
		;;
	esac
}

main "$@"
