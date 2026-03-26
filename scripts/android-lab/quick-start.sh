#!/usr/bin/env bash
# scripts/android-lab/quick-start.sh
# Starts a rooted lab AVD with a stable proxy-first workflow for Frida + mitmproxy.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
set -euo pipefail

AVD_NAME="play-avd"
PROXY_HOST="10.0.2.2"
PROXY_PORT="8080"
FLOW_FILE="/tmp/lab_traffic.flows"
MITM_CERT="${HOME}/.mitmproxy/mitmproxy-ca-cert.pem"
ENABLE_APEX_CERT_MOUNT="${ENABLE_APEX_CERT_MOUNT:-0}"

pick_proxy_port() {
	python - "$PROXY_PORT" <<'PY'
import socket
import sys

start = int(sys.argv[1])
for port in range(start, start + 20):
    with socket.socket() as sock:
        try:
            sock.bind(("127.0.0.1", port))
        except OSError:
            continue
        else:
            print(port)
            raise SystemExit(0)

raise SystemExit(1)
PY
}

cleanup() {
	if [[ -n "${EMU_PID:-}" ]]; then
		kill "${EMU_PID}" 2>/dev/null || true
	fi

	if [[ -n "${MITM_PID:-}" ]]; then
		kill "${MITM_PID}" 2>/dev/null || true
	fi

	adb shell settings put global http_proxy :0 >/dev/null 2>&1 || true
	adb shell "su 0 iptables -D OUTPUT -p udp --dport 443 -j REJECT" >/dev/null 2>&1 || true
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		print_error "Missing required command: $1"
		exit 1
	fi
}

wait_for_boot() {
	adb wait-for-device
	while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do
		sleep 5
	done
}

wait_for_root() {
	for _attempt in {1..20}; do
		if adb shell "su 0 id" >/dev/null 2>&1; then
			return 0
		fi
		sleep 2
	done

	print_error "Root shell did not become available"
	exit 1
}

log_info "=== Android Lab Quick Start ==="
trap cleanup EXIT

require_command adb
require_command emulator
require_command mitmdump
require_command openssl
require_command python

if [[ ! -f "${MITM_CERT}" ]]; then
	print_error "Missing mitmproxy CA certificate at ${MITM_CERT}"
	exit 1
fi

HASH="$(openssl x509 -inform PEM -subject_hash_old -in "${MITM_CERT}" | head -1)"
PROXY_PORT="$(pick_proxy_port)"

# Cleanup old lab processes/locks
pkill -f "qemu-system" 2>/dev/null || true
pkill -f mitmdump 2>/dev/null || true
sleep 2
rm -f "${HOME}/.android/avd/${AVD_NAME}.avd/"*.lock

# 1. Start mitmproxy in regular proxy mode
log_info "[1/6] Starting mitmproxy (:${PROXY_PORT})..."
rm -f "${FLOW_FILE}"
mitmdump -p "${PROXY_PORT}" -w "${FLOW_FILE}" --set flow_detail=3 --set block_global=false &
MITM_PID=$!
sleep 2

if ! kill -0 "${MITM_PID}" 2>/dev/null; then
	print_error "mitmdump failed to start on port ${PROXY_PORT}"
	exit 1
fi

# 2. Start emulator
log_info "[2/6] Starting emulator ${AVD_NAME}..."
emulator -avd "${AVD_NAME}" -no-window -no-audio -no-snapshot \
	-gpu swiftshader_indirect -memory 4096 -no-metrics &
EMU_PID=$!
wait_for_boot
print_success "Booted"

# 3. Ensure Google services and root are ready
log_info "[3/6] Enabling Google services and root access..."
adb shell "pm enable com.google.android.gms" >/dev/null 2>&1 || true
adb shell "pm enable com.google.android.gsf" >/dev/null 2>&1 || true
adb shell "pm enable com.android.vending" >/dev/null 2>&1 || true
wait_for_root
print_success "Root shell ready"

# 4. Stage cert without rebinding Conscrypt by default
log_info "[4/6] Staging MITM certificate..."
adb push "${MITM_CERT}" "/data/local/tmp/${HASH}.0" >/dev/null

if [[ "${ENABLE_APEX_CERT_MOUNT}" == "1" ]]; then
	log_warning "APEX cert bind-mount enabled; this may destabilize Android 14"
	adb shell "su 0 sh -c '
  mkdir -p /data/local/tmp/cacerts_overlay
  cp /apex/com.android.conscrypt/cacerts/* /data/local/tmp/cacerts_overlay/ 2>/dev/null
  cp /data/local/tmp/${HASH}.0 /data/local/tmp/cacerts_overlay/
  umount /apex/com.android.conscrypt/cacerts 2>/dev/null || true
  mount --bind /data/local/tmp/cacerts_overlay /apex/com.android.conscrypt/cacerts
'"
	print_success "MITM certificate mounted into APEX store"
else
	print_success "MITM certificate staged only (safe mode)"
fi

# 5. Configure stable proxying and disable QUIC fallback
log_info "[5/6] Configuring Android proxy and QUIC fallback..."
adb shell settings put global http_proxy "${PROXY_HOST}:${PROXY_PORT}"
adb shell "su 0 iptables -D OUTPUT -p udp --dport 443 -j REJECT" >/dev/null 2>&1 || true
adb shell "su 0 iptables -A OUTPUT -p udp --dport 443 -j REJECT"
print_success "Proxy configured"

# 6. Start frida-server
log_info "[6/6] Starting frida-server..."
adb shell "su 0 killall frida-server" >/dev/null 2>&1 || true
adb shell "su 0 sh -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'"
sleep 2
print_success "frida-server started"

echo ""
print_success "=== READY ==="
echo "Emulator: $(adb devices | grep emulator || true)"
echo "Root: $(adb shell 'su 0 id' 2>/dev/null)"
echo "Frida: $(adb shell 'su 0 pgrep frida-server' 2>/dev/null)"
echo "Proxy: ${PROXY_HOST}:${PROXY_PORT}"
echo "Flows: ${FLOW_FILE}"
echo "APEX cert mount: ${ENABLE_APEX_CERT_MOUNT}"
echo ""
echo "Install app:    adb install target.apk"
echo "Frida hook:     frida -U -f com.target.app -l hooks.js"
echo "Proxy off:      adb shell settings put global http_proxy :0"
echo "Unsafe MITM:    ENABLE_APEX_CERT_MOUNT=1 ./scripts/android-lab/quick-start.sh"
echo ""
echo "Ctrl+C to stop"
wait
