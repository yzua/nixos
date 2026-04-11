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
FRIDA_BIN="${FRIDA_BIN:-${HOME}/Downloads/android-re-tools/frida/frida-server-17.5.1-android-x86_64}"
FRIDA_TARGET="${FRIDA_TARGET:-/data/local/tmp/frida-server-17.5.1}"
FRIDA_LOG_PATH="${FRIDA_LOG_PATH:-/data/local/tmp/frida.log}"
FRIDA_WAIT_TIMEOUT="${FRIDA_WAIT_TIMEOUT:-10}"
FRIDA_WAIT_RETRIES="${FRIDA_WAIT_RETRIES:-3}"
MITM_CONF_DIR="${MITM_CONF_DIR:-${HOME}/Downloads/android-re-tools/custom-ca}"
MITM_CA_HASH="${MITM_CA_HASH:-}"
MITM_CA_SOURCE="${MITM_CA_SOURCE:-${MITM_CONF_DIR}/mitmproxy-ca-cert.cer}"
MITM_CA_TARGET=""
MITM_HOST="${MITM_HOST:-0.0.0.0}"
MITM_PORT="${MITM_PORT:-8084}"
PROXY_HOST="${PROXY_HOST:-10.0.2.2}"
MESA_EGL_VENDOR_FILE="${MESA_EGL_VENDOR_FILE:-/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json}"
NVIDIA_VULKAN_ICD="${NVIDIA_VULKAN_ICD:-/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json}"
EMU_GPU_MODE="${EMU_GPU_MODE:-auto}"
EMU_HEADLESS="${EMU_HEADLESS:-0}"
EMU_DISABLE_VULKAN="${EMU_DISABLE_VULKAN:-0}"
EMU_DISABLE_HARDWARE_DECODER="${EMU_DISABLE_HARDWARE_DECODER:-1}"
RE_ENABLE_PROXY="${RE_ENABLE_PROXY:-0}"
RE_SELINUX_PERMISSIVE="${RE_SELINUX_PERMISSIVE:-1}"
TMUX_SESSION="${TMUX_SESSION:-android-re}"
TMUX_SHELL_WINDOW="${TMUX_SHELL_WINDOW:-shell}"
TMUX_MITM_WINDOW="${TMUX_MITM_WINDOW:-mitm}"
TMUX_FRIDA_WINDOW="${TMUX_FRIDA_WINDOW:-frida}"
TMUX_LOG_WINDOW="${TMUX_LOG_WINDOW:-logs}"
TMUX_LOGCAT_WINDOW="${TMUX_LOGCAT_WINDOW:-logcat}"
RE_WORKSPACE="${RE_WORKSPACE:-6}"
RUNTIME_LOG="${RUNTIME_LOG:-${HOME}/Downloads/android-re-tools/emulator-runtime.log}"
BOOT_WAIT_TIMEOUT="${BOOT_WAIT_TIMEOUT:-180}"
RE_SPOOF_DEVICE="${RE_SPOOF_DEVICE:-1}"

# shellcheck source=scripts/ai/android-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"
# shellcheck source=scripts/ai/android-re/_spoof-table.sh
source "${SCRIPT_DIR}/_spoof-table.sh"

resolve_frida_ps_bin() {
	FRIDA_PS_BIN="$(command -v frida-ps || true)"
	[[ -n "${FRIDA_PS_BIN}" ]] || error_exit "missing frida-ps host tool"
}

frida_host_probe() {
	resolve_frida_ps_bin
	timeout "${FRIDA_WAIT_TIMEOUT}" "${FRIDA_PS_BIN}" -U >/dev/null 2>&1
}

log_frida_failure_context() {
	local remote_log

	remote_log="$(adb shell "su 0 sh -c 'tail -n 20 ${FRIDA_LOG_PATH} 2>/dev/null || true'" 2>/dev/null | tr -d '\r' || true)"
	if [[ -n "${remote_log}" ]]; then
		log_warning "recent Frida server log from ${FRIDA_LOG_PATH}:"
		printf '%s\n' "${remote_log}" >&2
	fi
}

init_mitm_ca_vars() {
	local cert_hash
	need_cmd openssl
	need_file "${MITM_CA_SOURCE}"

	cert_hash="$(
		openssl x509 -inform PEM -subject_hash_old -in "${MITM_CA_SOURCE}" -noout 2>/dev/null ||
			openssl x509 -subject_hash_old -in "${MITM_CA_SOURCE}" -noout 2>/dev/null
	)" || error_exit "failed to derive certificate hash from ${MITM_CA_SOURCE}"

	[[ -n "${cert_hash}" ]] || error_exit "empty certificate hash for ${MITM_CA_SOURCE}"

	if [[ -z "${MITM_CA_HASH}" ]]; then
		MITM_CA_HASH="${cert_hash}.0"
	fi

	MITM_CA_TARGET="/system/etc/security/cacerts/${MITM_CA_HASH}"
}

adb_run() {
	need_cmd adb
	adb "$@"
}

spoof_device() {
	local changed=0 failed=0
	log_info "spoofing device identity to look like a real ${SPOOF_DEVICE_MODEL}"

	# Resolve Magisk binary — it acts as a multi-call binary (resetprop, magisk, su, etc.)
	# On this AVD, Magisk is installed as an app; the binary lives under the app data directory.
	local resetprop_bin
	resetprop_bin="$(adb shell 'su 0 sh -c "ls /data/user/0/com.android.shell/Magisk/lib/x86_64/magisk 2>/dev/null || ls /data/adb/magisk/magisk 2>/dev/null || which magisk 2>/dev/null || echo """' 2>/dev/null | tr -d '\r' || true)"
	if [[ -z "${resetprop_bin}" ]]; then
		log_error "cannot find Magisk binary for resetprop"
		return 1
	fi
	log_info "using Magisk binary: ${resetprop_bin}"

	# Apply system properties via Magisk resetprop (bypasses ro.* read-only)
	local entry prop value old
	for entry in "${SPOOF_PROPS[@]}"; do
		IFS='|' read -r prop value <<<"${entry}"
		old="$(adb shell "su 0 getprop ${prop}" 2>/dev/null | tr -d '\r' || true)"
		if [[ "${old}" == "${value}" ]]; then
			continue
		fi
		if adb shell "su 0 ${resetprop_bin} resetprop ${prop} '${value}'" >/dev/null 2>&1; then
			changed=$((changed + 1))
		else
			log_warning "resetprop failed: ${prop}"
			failed=$((failed + 1))
		fi
	done

	# Hide emulator-indicator files (goldfish, qemu pipes)
	local emu_file
	for emu_file in "${SPOOF_HIDE_FILES[@]}"; do
		adb shell "su 0 sh -c 'if [ -e ${emu_file} ]; then mv ${emu_file} ${emu_file}.hidden; fi'" >/dev/null 2>&1 || true
	done

	# Kill emulator-specific services that aren't needed for app execution
	local svc
	for svc in "${SPOOF_STOP_SERVICES[@]}"; do
		adb shell "su 0 sh -c 'stop ${svc} 2>/dev/null || true'" >/dev/null 2>&1 || true
	done

	log_success "device spoof applied (${changed} props changed, ${failed} failed, ${#SPOOF_HIDE_FILES[@]} files hidden, ${#SPOOF_STOP_SERVICES[@]} services stopped)"

	# Quick verification
	log_info "identity check: hardware=$(adb shell getprop ro.hardware 2>/dev/null | tr -d '\r') model=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r') characteristics=$(adb shell getprop ro.build.characteristics 2>/dev/null | tr -d '\r')"
}

unspoof_device() {
	log_info "restoring original emulator identity"

	local emu_file
	for emu_file in "${SPOOF_HIDE_FILES[@]}"; do
		adb shell "su 0 sh -c 'if [ -e ${emu_file}.hidden ]; then mv ${emu_file}.hidden ${emu_file}; fi'" >/dev/null 2>&1 || true
	done

	# resetprop reverts are unreliable; recommend reboot for full restore
	log_warning "system property changes persist until emulator reboot"
	log_success "hidden files restored"
}

list_emulator_pids() {
	pgrep -f "qemu-system-.*@${AVD_NAME}([[:space:]]|\$)" || true
}

show_runtime_log_tail() {
	if [[ -f "${RUNTIME_LOG}" ]]; then
		log_warning "recent emulator log from ${RUNTIME_LOG}:"
		tail -n 20 "${RUNTIME_LOG}" >&2 || true
	fi
}

stop_stale_emulator_processes() {
	local pids

	pids="$(list_emulator_pids)"
	if [[ -z "${pids}" ]]; then
		return 0
	fi

	log_warning "stopping stale emulator process(es) for ${AVD_NAME}: ${pids//$'\n'/ }"
	while IFS= read -r pid; do
		[[ -n "${pid}" ]] || continue
		kill "${pid}" 2>/dev/null || true
	done <<<"${pids}"

	for _ in $(seq 1 10); do
		if [[ -z "$(list_emulator_pids)" ]]; then
			log_success "stale emulator process cleanup complete"
			return 0
		fi
		sleep 1
	done

	pids="$(list_emulator_pids)"
	if [[ -n "${pids}" ]]; then
		log_warning "forcing stale emulator process shutdown for ${AVD_NAME}: ${pids//$'\n'/ }"
		while IFS= read -r pid; do
			[[ -n "${pid}" ]] || continue
			kill -9 "${pid}" 2>/dev/null || true
		done <<<"${pids}"
	fi
}

kill_mitm_listeners() {
	pkill -f "mitmdump.*--listen-port ${MITM_PORT}" 2>/dev/null || true
	pkill -f "mitmproxy.*--listen-port ${MITM_PORT}" 2>/dev/null || true

	if command -v ss >/dev/null 2>&1 && ss -ltnH "( sport = :${MITM_PORT} )" | grep -q .; then
		log_warning "port ${MITM_PORT} still has a listener after mitm cleanup"
	fi
}

mitm_listener_ready() {
	command -v ss >/dev/null 2>&1 && ss -ltnH "( sport = :${MITM_PORT} )" | grep -q .
}

mitm_command() {
	printf 'mitmdump --set confdir=%q --listen-host %q --listen-port %q' "${MITM_CONF_DIR}" "${MITM_HOST}" "${MITM_PORT}"
}

resolve_re_workspace_ref() {
	local ref
	if ! command -v niri >/dev/null 2>&1; then
		printf '%s\n' "${RE_WORKSPACE}"
		return 0
	fi

	ref="$(niri msg workspaces 2>/dev/null | sed -n 's/.*"\([^"]*android[^"]*\)".*/\1/p' | head -n1)"
	if [[ -n "${ref}" ]]; then
		printf '%s\n' "${ref}"
	else
		printf '%s\n' "${RE_WORKSPACE}"
	fi
}

focus_re_workspace() {
	local workspace_ref
	if ! command -v niri >/dev/null 2>&1; then
		return 0
	fi
	workspace_ref="$(resolve_re_workspace_ref)"

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

sync_mitm_ca() {
	local device_cert
	init_mitm_ca_vars
	device_cert="/data/local/tmp/${MITM_CA_HASH}"

	adb_run push "${MITM_CA_SOURCE}" "${device_cert}" >/dev/null
	adb_run shell "su 0 sh -s" <<EOF
set -e
device_cert=${device_cert@Q}
tmp_copy='/data/local/tmp/tmp-ca-copy'
system_ca_dir='/system/etc/security/cacerts'
conscrypt_ca_dir='/apex/com.android.conscrypt/cacerts'

rm -rf "\$tmp_copy"
mkdir -p -m 700 "\$tmp_copy"
cp /apex/com.android.conscrypt/cacerts/* "\$tmp_copy"/

if ! mountpoint -q "\$system_ca_dir"; then
  mount -t tmpfs tmpfs "\$system_ca_dir"
fi

cp "\$tmp_copy"/* "\$system_ca_dir"/
cp "\$device_cert" "\$system_ca_dir/${MITM_CA_HASH}"
chown root:root "\$system_ca_dir"/*
chmod 644 "\$system_ca_dir"/*
chcon u:object_r:system_security_cacerts_file:s0 "\$system_ca_dir"/*
mount --bind "\$system_ca_dir" "\$conscrypt_ca_dir"

zygotes="\$(pidof zygote64 zygote webview_zygote com.android.chrome_zygote 2>/dev/null || true)"
for pid in \$zygotes; do
  nsenter --mount=/proc/\$pid/ns/mnt -- mount --bind "\$system_ca_dir" "\$conscrypt_ca_dir"
done

app_pids="\$(for z in \$zygotes; do ps -A -o PID,PPID | awk -v z="\$z" '\$2==z{print \$1}'; done | sort -u)"
for pid in \$app_pids; do
  nsenter --mount=/proc/\$pid/ns/mnt -- mount --bind "\$system_ca_dir" "\$conscrypt_ca_dir" || true
done
EOF

	log_success "mitmproxy system CA synced from ${MITM_CA_SOURCE}"
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

start_mitm_tmux() {
	need_cmd mitmdump
	need_file "${MITM_CONF_DIR}/mitmproxy-ca-cert.cer"
	kill_mitm_listeners
	ensure_re_tmux

	if mitm_listener_ready; then
		log_success "mitmproxy listener already present on ${MITM_PORT}"
		return 0
	fi

	tmux send-keys -t "${TMUX_SESSION}:${TMUX_MITM_WINDOW}" C-c
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_MITM_WINDOW}" "clear"
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_MITM_WINDOW}" Enter
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_MITM_WINDOW}" "$(mitm_command)"
	tmux send-keys -t "${TMUX_SESSION}:${TMUX_MITM_WINDOW}" Enter

	for _ in $(seq 1 15); do
		if mitm_listener_ready; then
			log_success "mitmproxy listening on ${MITM_HOST}:${MITM_PORT}"
			return 0
		fi
		sleep 1
	done

	error_exit "mitmproxy did not start on port ${MITM_PORT}"
}

warn_stale_host_proxy() {
	local proxy host port
	proxy="$(adb shell settings get global http_proxy 2>/dev/null | tr -d '\r' || true)"

	if [[ -z "${proxy}" || "${proxy}" == ":0" || "${proxy}" == "null" ]]; then
		return 0
	fi

	host="${proxy%%:*}"
	port="${proxy##*:}"

	if [[ "${host}" != "10.0.2.2" || ! "${port}" =~ ^[0-9]+$ ]]; then
		return 0
	fi

	if ! command -v ss >/dev/null 2>&1; then
		log_warning "emulator proxy is set to ${proxy}; install 'ss' host-side to verify the listener"
		return 0
	fi

	if ! ss -ltnH "( sport = :${port} )" | grep -q .; then
		log_warning "emulator proxy points to ${proxy}, but nothing is listening on host port ${port}"
		log_warning "run 'bash scripts/ai/android-re/re-avd.sh proxy-clear' or start mitmdump on ${port}"
	fi
}

wait_boot() {
	if ! timeout "${BOOT_WAIT_TIMEOUT}" adb wait-for-device >/dev/null 2>&1; then
		log_error "emulator did not register with adb within ${BOOT_WAIT_TIMEOUT}s"
		show_runtime_log_tail
		return 1
	fi

	local waited=0
	until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
		if ((waited >= BOOT_WAIT_TIMEOUT)); then
			log_error "emulator boot did not complete within ${BOOT_WAIT_TIMEOUT}s"
			show_runtime_log_tail
			return 1
		fi
		sleep 2
		waited=$((waited + 2))
	done
}

start_emulator() {
	need_cmd emulator
	local -a emulator_args
	local -a env_args
	local qt_platform="${QT_QPA_PLATFORM:-xcb}"
	local headless="${EMU_HEADLESS}"
	local gpu_mode="${EMU_GPU_MODE}"
	stop_all_emulators
	log_info "starting emulator ${AVD_NAME}"

	if [[ "${gpu_mode}" == "auto" && -f "${NVIDIA_VULKAN_ICD}" ]]; then
		gpu_mode="host"
		log_info "detected NVIDIA Vulkan ICD; preferring host GPU mode over emulator auto"
	fi

	emulator_args=(
		@"${AVD_NAME}"
		-writable-system
		-no-snapshot
		-no-metrics
		-gpu "${gpu_mode}"
		-netdelay none
		-netspeed full
	)

	if [[ "${EMU_DISABLE_HARDWARE_DECODER}" == "1" ]]; then
		emulator_args+=(-feature -HardwareDecoder)
	fi

	if [[ "${EMU_DISABLE_VULKAN}" == "1" ]]; then
		emulator_args+=(-feature -Vulkan)
	fi

	if [[ "${headless}" != "1" && -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
		headless="1"
		log_warning "no DISPLAY or WAYLAND_DISPLAY in this shell; falling back to headless emulator mode"
	fi

	if [[ "${headless}" == "1" ]]; then
		qt_platform="offscreen"
		emulator_args+=(-no-window)
	elif [[ -z "${DISPLAY:-}" && -n "${WAYLAND_DISPLAY:-}" && -z "${QT_QPA_PLATFORM:-}" ]]; then
		qt_platform="wayland;xcb"
	fi

	env_args=(
		QT_QPA_PLATFORM="${qt_platform}"
		ANDROID_EMULATOR_GPU_MODE="${gpu_mode}"
	)

	if [[ "${gpu_mode}" != "software" && -f "${NVIDIA_VULKAN_ICD}" ]]; then
		env_args+=(
			__GLX_VENDOR_LIBRARY_NAME="${__GLX_VENDOR_LIBRARY_NAME:-nvidia}"
			VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-${NVIDIA_VULKAN_ICD}}"
			VK_LOADER_LAYERS_DISABLE="${VK_LOADER_LAYERS_DISABLE:-~implicit~explicit}"
		)
	fi

	nohup env "${env_args[@]}" emulator "${emulator_args[@]}" >"${RUNTIME_LOG}" 2>&1 &
	log_info "emulator gpu=${gpu_mode} headless=${headless} disable_vulkan=${EMU_DISABLE_VULKAN} disable_hw_decoder=${EMU_DISABLE_HARDWARE_DECODER}"
	log_success "emulator started; log=${RUNTIME_LOG}"
	wait_boot
	log_success "emulator boot complete"
	warn_stale_host_proxy
}

start_re() {
	start_emulator
	start_mitm_tmux
	open_re_terminal
	if [[ "${RE_SELINUX_PERMISSIVE}" == "1" ]]; then
		set_selinux_mode permissive
	else
		set_selinux_mode enforcing
	fi
	if [[ "${RE_SPOOF_DEVICE}" == "1" ]]; then
		spoof_device
	fi
	sync_mitm_ca
	if ! frida_start; then
		log_warning "continuing without a confirmed Frida connection so tmux and OpenCode still start"
	fi
	if [[ "${RE_ENABLE_PROXY}" == "1" ]]; then
		proxy_set "${PROXY_HOST}:${MITM_PORT}" 1
	else
		proxy_clear
		log_info "proxy disabled by default; set RE_ENABLE_PROXY=1 to route emulator traffic through mitmproxy"
	fi
	status
}

stop_emulator() {
	if adb devices 2>/dev/null | grep -q '^emulator-'; then
		log_info "stopping emulator"
		adb_run emu kill || true
	else
		log_warning "no running emulator detected"
	fi
}

stop_all_emulators() {
	local serial found=0
	while IFS= read -r serial; do
		[[ -n "${serial}" ]] || continue
		found=1
		log_info "stopping running emulator ${serial}"
		adb -s "${serial}" emu kill || true
	done < <(adb devices 2>/dev/null | grep '^emulator-' | cut -f1)

	if [[ "${found}" == "0" ]]; then
		log_warning "no running emulators detected"
	fi

	stop_stale_emulator_processes

	for _ in $(seq 1 20); do
		if ! adb devices 2>/dev/null | grep -q '^emulator-' && [[ -z "$(list_emulator_pids)" ]]; then
			log_success "all running emulators stopped"
			return 0
		fi
		sleep 1
	done

	log_warning "some emulators may still be shutting down"
}

root_check() {
	adb_run shell 'su 0 sh -c id'
}

set_selinux_mode() {
	local mode="$1"
	local current

	current="$(adb shell getenforce 2>/dev/null | tr -d '\r' || true)"

	if [[ "${mode}" == "permissive" ]]; then
		if [[ "${current}" != "Permissive" ]]; then
			adb_run shell 'su 0 setenforce 0'
		fi
	else
		if [[ "${current}" != "Enforcing" ]]; then
			adb_run shell 'su 0 setenforce 1'
		fi
	fi

	log_success "SELinux mode: $(adb shell getenforce 2>/dev/null | tr -d '\r' || true)"
}

cert_check() {
	init_mitm_ca_vars
	adb_run shell "ls -l ${MITM_CA_TARGET}"
	adb_run shell "ls -l /apex/com.android.conscrypt/cacerts/${MITM_CA_HASH}"
}

frida_start() {
	local attempt

	need_file "${FRIDA_BIN}"
	resolve_frida_ps_bin
	log_info "deploying frida server"
	adb_run push "${FRIDA_BIN}" "${FRIDA_TARGET}" >/dev/null
	adb_run shell "su 0 sh -c 'chmod 755 ${FRIDA_TARGET} && pkill -x $(basename "${FRIDA_TARGET}") 2>/dev/null || true && nohup ${FRIDA_TARGET} -l 0.0.0.0:27042 >${FRIDA_LOG_PATH} 2>&1 &'"

	for attempt in $(seq 1 "${FRIDA_WAIT_RETRIES}"); do
		sleep 2
		if frida_host_probe; then
			log_success "frida server reachable"
			return 0
		fi
		log_warning "frida probe attempt ${attempt}/${FRIDA_WAIT_RETRIES} timed out after ${FRIDA_WAIT_TIMEOUT}s"
	done

	log_frida_failure_context
	return 1
}

frida_stop() {
	adb_run shell "su 0 sh -c 'pkill -x $(basename "${FRIDA_TARGET}") 2>/dev/null || true'"
	log_success "frida server stopped"
}

proxy_set() {
	local proxy="$1"
	local block_quic="${2:-0}"
	adb_run shell settings put global http_proxy "${proxy}"
	log_success "http proxy set to ${proxy}"
	if [[ "${block_quic}" == "1" ]]; then
		adb_run shell "su 0 sh -c 'iptables -C OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null || iptables -A OUTPUT -p udp --dport 443 -j REJECT; ip6tables -C OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null || ip6tables -A OUTPUT -p udp --dport 443 -j REJECT'"
		log_success "QUIC blocking rules applied"
	fi
}

proxy_clear() {
	adb_run shell settings put global http_proxy :0
	adb_run shell "su 0 sh -c 'iptables -D OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null || true; ip6tables -D OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null || true'"
	log_success "proxy cleared and QUIC block rules removed"
}

status() {
	init_mitm_ca_vars
	log_info "avd: ${AVD_NAME}"
	if command -v emulator >/dev/null 2>&1; then
		if emulator -list-avds | grep -Fx "${AVD_NAME}" >/dev/null; then
			log_success "avd exists"
		else
			log_warning "avd missing"
		fi
	fi
	adb devices -l || true
	if adb devices 2>/dev/null | grep -q '^emulator-'; then
		log_info "boot=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
		log_info "device_identity=$(adb shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r' || true)/$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
		if adb shell 'su 0 sh -c id' >/dev/null 2>&1; then
			log_success "unattended root works"
		else
			log_warning "unattended root failed"
		fi
		if adb shell "ls ${MITM_CA_TARGET}" >/dev/null 2>&1; then
			log_success "mitmproxy system CA installed"
		else
			log_warning "mitmproxy system CA missing"
		fi
		log_info "proxy=$(adb shell settings get global http_proxy 2>/dev/null | tr -d '\r' || true)"
		warn_stale_host_proxy
		if [[ ! -x "${FRIDA_PS_BIN}" ]]; then
			FRIDA_PS_BIN="$(command -v frida-ps || true)"
		fi
		if [[ -n "${FRIDA_PS_BIN}" ]] && frida_host_probe; then
			log_success "frida reachable"
		else
			log_warning "frida not reachable"
		fi
	else
		log_warning "no emulator device online"
	fi
}

doctor() {
	init_mitm_ca_vars
	for tool in adb emulator avdmanager sdkmanager mitmproxy mitmdump frida frida-ps apktool jadx sqlite3 unzip xz; do
		if command -v "$tool" >/dev/null 2>&1; then
			log_success "tool present: ${tool} -> $(command -v "$tool")"
		else
			log_warning "tool missing: ${tool}"
		fi
	done
	if [[ -d "${HOME}/.android/avd/${AVD_NAME}.avd" ]]; then
		log_success "avd directory exists"
	else
		log_warning "avd directory missing"
	fi
	if [[ -x "${FRIDA_BIN}" ]]; then
		log_success "frida server binary ready"
	else
		log_warning "frida server binary missing: ${FRIDA_BIN}"
	fi
	if [[ -f "${MITM_CA_SOURCE}" ]]; then
		log_success "mitmproxy CA source present"
	else
		log_warning "mitmproxy CA source missing: ${MITM_CA_SOURCE}"
	fi
}

usage() {
	cat <<'EOF'
Usage: re-avd.sh <command> [args]

Env:
  EMU_GPU_MODE                  Emulator GPU mode (default: auto)
  EMU_HEADLESS                  Use -no-window with QT offscreen (default: 0)
  EMU_DISABLE_VULKAN            Pass -feature -Vulkan to disable guest Vulkan (default: 0)
  EMU_DISABLE_HARDWARE_DECODER  Pass -feature -HardwareDecoder (default: 1)
  RE_ENABLE_PROXY               Set to 1 to apply emulator proxy + QUIC blocking (default: 0)
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
