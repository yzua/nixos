#!/usr/bin/env bash
# Frida server deployment and lifecycle management.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/android-re/_helpers.sh

FRIDA_VERSION="${FRIDA_VERSION:-17.5.1}"
FRIDA_BIN="${FRIDA_BIN:-${HOME}/Downloads/android-re-tools/frida/frida-server-${FRIDA_VERSION}-android-x86_64}"
FRIDA_TARGET="${FRIDA_TARGET:-/data/local/tmp/frida-server-${FRIDA_VERSION}}"
FRIDA_LOG_PATH="${FRIDA_LOG_PATH:-/data/local/tmp/frida.log}"
FRIDA_PS_BIN="${FRIDA_PS_BIN:-}"
FRIDA_WAIT_TIMEOUT="${FRIDA_WAIT_TIMEOUT:-10}"
FRIDA_WAIT_RETRIES="${FRIDA_WAIT_RETRIES:-3}"

resolve_frida_ps_bin() {
	FRIDA_PS_BIN="$(command -v frida-ps || true)"
	[[ -n "${FRIDA_PS_BIN}" ]] || error_exit "missing frida-ps host tool"
}

frida_host_probe() {
	resolve_frida_ps_bin
	# Check that frida-ps actually lists processes (not just exits 0 with empty output).
	# frida-ps -U returns exit 0 even when the server is down (just prints nothing).
	# Count lines — a working server lists 50+ processes.
	local lines
	lines="$(timeout -k 3 "${FRIDA_WAIT_TIMEOUT}" "${FRIDA_PS_BIN}" -U 2>/dev/null | wc -l)" || lines=0
	((lines > 5))
}

log_frida_failure_context() {
	local remote_log

	remote_log="$(adb_prop "su 0 sh -c 'tail -n 20 ${FRIDA_LOG_PATH} 2>/dev/null || true'")"
	if [[ -n "${remote_log}" ]]; then
		log_warning "recent Frida server log from ${FRIDA_LOG_PATH}:"
		printf '%s\n' "${remote_log}" >&2
	fi
}

download_frida_server() {
	local frida_dir
	frida_dir="$(dirname "${FRIDA_BIN}")"
	mkdir -p "${frida_dir}"

	if [[ -x "${FRIDA_BIN}" ]]; then
		return 0
	fi

	local url="https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/frida-server-${FRIDA_VERSION}-android-x86_64.xz"
	local tmp_xz="${frida_dir}/frida-server-${FRIDA_VERSION}-android-x86_64.xz"

	log_info "downloading frida-server ${FRIDA_VERSION} from GitHub"
	need_cmd curl
	need_cmd xz

	curl -fSL -o "${tmp_xz}" "${url}"
	xz -d "${tmp_xz}"
	chmod +x "${FRIDA_BIN}"

	if [[ ! -x "${FRIDA_BIN}" ]]; then
		error_exit "frida-server download failed — ${FRIDA_BIN} not executable"
	fi
	log_success "frida-server ${FRIDA_VERSION} downloaded"
}

frida_start() {
	local attempt

	download_frida_server
	resolve_frida_ps_bin
	log_info "deploying frida server"
	adb_run push "${FRIDA_BIN}" "${FRIDA_TARGET}" >/dev/null

	# Kill any existing frida server before starting a new one
	adb_run shell "su 0 sh -c 'pkill -x $(basename "${FRIDA_TARGET}") 2>/dev/null || true'" >/dev/null
	sleep 1

	# Start frida server. Background the entire adb call on the host side
	# because adb shell hangs when the remote command spawns a background child.
	# The server will be ready in a few seconds; we probe below.
	(
		adb shell "su 0 sh -c 'chmod 755 ${FRIDA_TARGET} && ${FRIDA_TARGET} -l 0.0.0.0:27042 </dev/null >${FRIDA_LOG_PATH} 2>&1 &'" >/dev/null 2>&1
	) &

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
