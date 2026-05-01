#!/usr/bin/env bash
# MITM proxy (mitmproxy) setup and configuration for web RE.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/web-re/_helpers.sh

MITM_CONF_DIR="${MITM_CONF_DIR:-${HOME}/Downloads/web-re-tools/custom-ca}"
MITM_HOST="${MITM_HOST:-0.0.0.0}"
MITM_PORT="${MITM_PORT:-8084}"

kill_mitm_listeners() {
	pkill -f "mitmdump.*--listen-port ${MITM_PORT}" 2>/dev/null || true
	pkill -f "mitmproxy.*--listen-port ${MITM_PORT}" 2>/dev/null || true

	for _ in $(seq 1 10); do
		if ! port_in_use "${MITM_PORT}"; then
			return 0
		fi
		sleep 0.5
	done

	if port_in_use "${MITM_PORT}"; then
		log_warning "port ${MITM_PORT} still has a listener after mitm cleanup -- killing forcefully"
		ss -ltnpH "( sport = :${MITM_PORT} )" | grep -oP 'pid=\K[0-9]+' | xargs -r kill -9 2>/dev/null || true
		sleep 1
	fi
}

mitm_running() {
	port_in_use "${MITM_PORT}"
}

mitm_command() {
	printf 'mitmdump --set confdir=%q --listen-host %q --listen-port %q --set ssl_insecure=true --set flow_detail=2' "${MITM_CONF_DIR}" "${MITM_HOST}" "${MITM_PORT}"
}

mitm_start() {
	need_cmd mitmdump

	if [[ ! -e "${MITM_CONF_DIR}/mitmproxy-ca-cert.cer" ]]; then
		log_info "generating mitmproxy CA cert in ${MITM_CONF_DIR}"
		mkdir -p "${MITM_CONF_DIR}"
		mitmdump --set confdir="${MITM_CONF_DIR}" -q &
		local mitm_pid=$!
		sleep 3
		kill "${mitm_pid}" 2>/dev/null || true
		wait "${mitm_pid}" 2>/dev/null || true
		if [[ ! -e "${MITM_CONF_DIR}/mitmproxy-ca-cert.cer" ]]; then
			log_warning "failed to generate mitmproxy CA cert in ${MITM_CONF_DIR}"
			return 1
		fi
		log_success "mitmproxy CA cert generated"
	fi

	kill_mitm_listeners

	if mitm_running; then
		log_success "mitmproxy listener already present on ${MITM_PORT}"
		return 0
	fi

	# Start mitmdump in tmux if available, otherwise background
	if command -v tmux >/dev/null 2>&1 && tmux has-session -t "${TMUX_SESSION:-web-re}" 2>/dev/null; then
		tmux send-keys -t "${TMUX_SESSION:-web-re}:${TMUX_MITM_WINDOW:-mitm}" C-c
		tmux send-keys -t "${TMUX_SESSION:-web-re}:${TMUX_MITM_WINDOW:-mitm}" "clear"
		tmux send-keys -t "${TMUX_SESSION:-web-re}:${TMUX_MITM_WINDOW:-mitm}" Enter
		tmux send-keys -t "${TMUX_SESSION:-web-re}:${TMUX_MITM_WINDOW:-mitm}" "$(mitm_command)"
		tmux send-keys -t "${TMUX_SESSION:-web-re}:${TMUX_MITM_WINDOW:-mitm}" Enter
	else
		nohup "$(mitm_command)" >/dev/null 2>&1 &
		disown 2>/dev/null || true
	fi

	for _ in $(seq 1 15); do
		if mitm_running; then
			log_success "mitmproxy listening on ${MITM_HOST}:${MITM_PORT}"
			return 0
		fi
		sleep 1
	done

	error_exit "mitmproxy did not start on port ${MITM_PORT}"
}

mitm_stop() {
	kill_mitm_listeners
	log_success "mitmproxy stopped"
}
