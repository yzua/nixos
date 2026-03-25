#!/usr/bin/env bash
# scripts/android-lab/quick-start.sh
# Starts lab-avd + frida-server + mitmproxy (transparent) + iptables redirect
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
set -euo pipefail

AVD_NAME="lab-avd"

log_info "=== Android Lab Quick Start ==="

# Cleanup
pkill -f "qemu-system" 2>/dev/null || true
pkill -f mitmdump 2>/dev/null || true
sleep 2
rm -f "$HOME/.android/avd/${AVD_NAME}.avd/"*.lock

# 1. Start mitmproxy transparent
log_info "[1/4] Starting mitmproxy (transparent :8080)..."
mitmdump --mode transparent -p 8080 -w /tmp/lab_traffic.flows --set flow_detail=3 &
MITM_PID=$!
sleep 2

# 2. Start emulator
log_info "[2/4] Starting emulator..."
emulator -avd "$AVD_NAME" -no-window -no-audio -no-snapshot \
	-gpu swiftshader_indirect -memory 4096 -no-metrics &
EMU_PID=$!
adb wait-for-device
while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do sleep 5; done
print_success "Booted!"

# 3. iptables redirect (needs root via Magisk)
log_info "[3/4] Setting iptables redirect..."
adb shell "su -c 'iptables -t nat -F OUTPUT'" 2>/dev/null
adb shell "su -c 'iptables -t nat -A OUTPUT -p tcp --dport 443 -j DNAT --to-destination 10.0.2.2:8080'" 2>/dev/null
adb shell "su -c 'iptables -t nat -A OUTPUT -p tcp --dport 80 -j DNAT --to-destination 10.0.2.2:8080'" 2>/dev/null
print_success "iptables set"

# 4. Start frida-server
log_info "[4/4] Starting frida-server..."
adb shell "su 0 killall frida-server 2>/dev/null"
adb shell "su 0 /data/local/tmp/frida-server &" 2>/dev/null
sleep 2

# 5. Bind mount MITM cert (Android 14 APEX workaround)
log_info "[5/5] Installing MITM cert (bind mount)..."
adb shell "su 0 sh -c '
  mkdir -p /data/local/tmp/cacerts_overlay
  cp /apex/com.android.conscrypt/cacerts/* /data/local/tmp/cacerts_overlay/ 2>/dev/null
  cp /data/local/tmp/c8750f0d.0 /data/local/tmp/cacerts_overlay/ 2>/dev/null
  mount --bind /data/local/tmp/cacerts_overlay /apex/com.android.conscrypt/cacerts
'" 2>/dev/null
print_success "MITM cert installed"

# Verify
echo ""
print_success "=== READY ==="
echo "Emulator: $(adb devices | grep emulator)"
echo "Root: $(adb shell 'su -c id' 2>/dev/null)"
echo "Frida: $(adb shell 'su -c pgrep frida-server' 2>/dev/null)"
echo "mitmproxy: PID $MITM_PID -> /tmp/lab_traffic.flows"
echo ""
echo "Install app:    adb install target.apk"
echo "Frida hook:     frida -U -f com.target.app -l hooks.js"
echo ""
echo "Ctrl+C to stop"
trap 'kill $MITM_PID $EMU_PID 2>/dev/null; adb shell settings put global http_proxy :0 2>/dev/null' EXIT
wait
