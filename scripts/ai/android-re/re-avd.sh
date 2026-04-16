#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

trap 'log_error "command failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

AVD_NAME="${AVD_NAME:-re-pixel7-api34}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${HOME}/Android/Sdk}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"
RUNTIME_LOG="${RUNTIME_LOG:-${HOME}/Downloads/android-re-tools/emulator-runtime.log}"

# shellcheck source=scripts/ai/android-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
# shellcheck source=scripts/ai/android-re/_spoof-table.sh
source "${SCRIPT_DIR}/_spoof-table.sh"
# shellcheck source=scripts/ai/android-re/_frida.sh
source "${SCRIPT_DIR}/_frida.sh"
# shellcheck source=scripts/ai/android-re/_tmux.sh
source "${SCRIPT_DIR}/_tmux.sh"
# shellcheck source=scripts/ai/android-re/_spoof.sh
source "${SCRIPT_DIR}/_spoof.sh"
# shellcheck source=scripts/ai/android-re/_emulator.sh
source "${SCRIPT_DIR}/_emulator.sh"
# shellcheck source=scripts/ai/android-re/_mitm.sh
source "${SCRIPT_DIR}/_mitm.sh"
# shellcheck source=scripts/ai/android-re/_status.sh
source "${SCRIPT_DIR}/_status.sh"

start_re() {
	# ── Phase 1: Full cleanup of stale state ──
	log_info "cleaning up stale RE state"

	# Kill stale mitmproxy listeners on our port
	kill_mitm_listeners

	# Kill stale frida server on device (if emulator is reachable)
	if emulator_online; then
		adb shell "su 0 sh -c 'pkill -9 frida-server 2>/dev/null || true'" >/dev/null 2>&1 || true
	fi

	# Kill stale emulator processes
	stop_all_emulators

	log_success "cleanup complete"

	# ── Phase 2: Boot emulator ──
	start_emulator

	# ── Phase 3: Set up tmux + mitmproxy ──
	start_mitm_tmux

	# ── Phase 4: Open Ghostty terminal on android workspace ──
	open_re_terminal

	# ── Phase 5: Root + SELinux ──
	if [[ "${RE_SELINUX_PERMISSIVE}" == "1" ]]; then
		set_selinux_mode permissive
	else
		set_selinux_mode enforcing
	fi

	# ── Phase 6: Device spoofing ──
	if [[ "${RE_SPOOF_DEVICE}" == "1" ]]; then
		spoof_device
	fi

	# ── Phase 7: Inject mitmproxy CA into system trust store ──
	sync_mitm_ca

	# ── Phase 8: Deploy and start Frida server ──
	if ! frida_start; then
		log_warning "continuing without a confirmed Frida connection so tmux and OpenCode still start"
	fi

	# ── Phase 9: Enable proxy + QUIC blocking (controlled by RE_ENABLE_PROXY) ──
	if [[ "${RE_ENABLE_PROXY}" == "1" ]]; then
		proxy_set "${PROXY_HOST}:${MITM_PORT}" 1
	fi

	# ── Phase 10: Final health report ──
	status
}

usage() {
	cat <<'EOF'
Usage: re-avd.sh <command> [args]

Env:
  EMU_GPU_MODE                  Emulator GPU mode (default: auto)
  EMU_HEADLESS                  Use -no-window with QT offscreen (default: 0)
  EMU_DISABLE_VULKAN            Pass -feature -Vulkan to disable guest Vulkan (default: 0)
  EMU_DISABLE_HARDWARE_DECODER  Pass -feature -HardwareDecoder (default: 1)
  RE_ENABLE_PROXY               Set to 1 to apply emulator proxy + QUIC blocking (default: 1)
  RE_SELINUX_PERMISSIVE         Set to 1 to switch guest SELinux to permissive for app root workflows (default: 1)
  RE_SPOOF_DEVICE               Set to 1 to spoof device identity on start (default: 1)

Commands:
  start                         Boot the rooted RE AVD and wire Frida + mitmproxy
  start-basic                   Boot only the rooted analysis AVD
  attach                        Attach Ghostty to the Android RE tmux session
  stop                          Stop the running emulator
  status                        Show runtime health, root, cert, and Frida state
  root-check                    Verify unattended su with Magisk
  frida-start                   Push and start Frida server
  frida-stop                    Stop Frida server
  proxy-set HOST:PORT [--block-quic]
                                Set global proxy and optionally block UDP/443
  proxy-clear                   Clear global proxy and unblock QUIC
  cert-check                    Verify system CA placement
  spoof                         Spoof device identity to look like a real Pixel 7
  unspoof                       Restore hidden emulator files (props need reboot)
  doctor                        Inventory required tools and artifacts
EOF
}

main() {
	local cmd="${1:-}"
	case "${cmd}" in
	start)
		start_re
		;;
	start-basic)
		start_emulator
		;;
	attach)
		attach_tmux
		;;
	stop)
		stop_emulator
		;;
	status)
		status
		;;
	root-check)
		root_check
		;;
	frida-start)
		frida_start
		;;
	frida-stop)
		frida_stop
		;;
	proxy-set)
		[[ -n "${2:-}" ]] || error_exit "proxy-set requires HOST:PORT"
		if [[ "${3:-}" == "--block-quic" ]]; then
			proxy_set "$2" 1
		else
			proxy_set "$2" 0
		fi
		;;
	proxy-clear)
		proxy_clear
		;;
	cert-check)
		cert_check
		;;
	spoof)
		spoof_device
		;;
	unspoof)
		unspoof_device
		;;
	doctor)
		doctor
		;;
	*)
		usage
		exit 1
		;;
	esac
}

main "$@"
