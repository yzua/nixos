#!/usr/bin/env bash
# Chrome browser management for web RE sessions.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/web-re/_helpers.sh

CHROME_DEBUG_PORT="${CHROME_DEBUG_PORT:-9222}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-${HOME}/.cache/web-re-tools/chrome-profile}"

# Detect available Chrome binary.
_chrome_binary() {
	if command -v google-chrome-stable >/dev/null 2>&1; then
		printf '%s' "google-chrome-stable"
	elif command -v chromium >/dev/null 2>&1; then
		printf '%s' "chromium"
	else
		return 1
	fi
}

# Launch Chrome with remote debugging enabled.
# Usage: chrome_start [URL]
chrome_start() {
	local chrome_bin
	chrome_bin="$(_chrome_binary)" || error_exit "neither google-chrome-stable nor chromium found in PATH"

	mkdir -p "${CHROME_PROFILE_DIR}"

	if chrome_running; then
		_write_devtools_active_port
		log_success "Chrome already running with remote debugging on port ${CHROME_DEBUG_PORT}"
		return 0
	fi

	local url="${1:-}"
	local -a cmd=(
		"${chrome_bin}"
		"--remote-debugging-port=${CHROME_DEBUG_PORT}"
		"--remote-allow-origins=*"
		"--no-first-run"
		"--disable-extensions"
		"--user-data-dir=${CHROME_PROFILE_DIR}"
	)

	if [[ -n "${url}" ]]; then
		cmd+=("${url}")
	fi

	log_info "starting Chrome with remote debugging on port ${CHROME_DEBUG_PORT}"
	nohup "${cmd[@]}" >/dev/null 2>&1 &
	local chrome_pid=$!
	disown "${chrome_pid}" 2>/dev/null || true

	# Wait for Chrome to start listening
	for _ in $(seq 1 15); do
		if chrome_running; then
			_write_devtools_active_port
			log_success "Chrome started (PID ${chrome_pid}, debug port ${CHROME_DEBUG_PORT})"
			return 0
		fi
		sleep 1
	done

	error_exit "Chrome did not start listening on port ${CHROME_DEBUG_PORT}"
}

# Stop Chrome gracefully.
chrome_stop() {
	local chrome_bin
	chrome_bin="$(_chrome_binary)" 2>/dev/null || true

	# Try graceful kill first
	pkill -f "chrome.*--remote-debugging-port=${CHROME_DEBUG_PORT}" 2>/dev/null || \
		pkill -f "chromium.*--remote-debugging-port=${CHROME_DEBUG_PORT}" 2>/dev/null || true

	for _ in $(seq 1 10); do
		if ! chrome_running; then
			log_success "Chrome stopped"
			return 0
		fi
		sleep 0.5
	done

	# Force kill if still running
	if chrome_running; then
		log_warning "Chrome still running -- killing forcefully"
		ss -ltnpH "( sport = :${CHROME_DEBUG_PORT} )" | grep -oP 'pid=\K[0-9]+' | xargs -r kill -9 2>/dev/null || true
		sleep 1
		if ! chrome_running; then
			log_success "Chrome stopped (forced)"
		else
			log_warning "port ${CHROME_DEBUG_PORT} still has a listener after forced kill"
		fi
	fi
}

# Check if Chrome remote debugging is listening.
chrome_status() {
	if chrome_running; then
		log_success "Chrome remote debugging active on port ${CHROME_DEBUG_PORT}"
	else
		log_info "Chrome remote debugging not running"
	fi
}

# Open a URL in the running Chrome instance.
# Usage: chrome_open_url URL
chrome_open_url() {
	local url="$1"
	[[ -n "${url}" ]] || error_exit "chrome_open_url requires a URL"

	if ! chrome_running; then
		log_warning "Chrome not running -- use chrome_start first"
		return 1
	fi

	local chrome_bin
	chrome_bin="$(_chrome_binary)" 2>/dev/null || true

	if [[ -n "${chrome_bin}" ]]; then
		nohup "${chrome_bin}" "--app=${url}" >/dev/null 2>&1 & disown 2>/dev/null || true
	else
		need_cmd xdg-open
		xdg-open "${url}" >/dev/null 2>&1 & disown 2>/dev/null || true
	fi
	log_success "opened ${url} in Chrome"
}

# Write DevToolsActivePort to the default Chrome config directory so
# chrome-devtools MCP servers (which use --autoConnect) can discover it.
# When Chrome runs with a custom --user-data-dir, it writes the file there
# instead of the default location that MCP servers expect.
_write_devtools_active_port() {
	local default_chrome_config="${HOME}/.config/google-chrome"
	local ws_url
	ws_url="$(curl -s "http://localhost:${CHROME_DEBUG_PORT}/json/version" 2>/dev/null | jq -r '.webSocketDebuggerUrl // empty' 2>/dev/null)" || return 0
	[[ -n "${ws_url}" ]] || return 0

	local ws_path
	ws_path="$(printf '%s' "${ws_url}" | sed 's|ws://localhost:[0-9]*||')"
	mkdir -p "${default_chrome_config}"
	printf '%s\n%s\n' "${CHROME_DEBUG_PORT}" "${ws_path}" >"${default_chrome_config}/DevToolsActivePort"
}
