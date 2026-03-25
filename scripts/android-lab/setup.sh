#!/usr/bin/env bash
# scripts/android-lab/setup.sh
# Creates lab-avd (rooted google_apis), installs frida-server + MITM cert
# Run ONCE, then use quick-start.sh for daily use
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
set -euo pipefail

AVD_NAME="lab-avd"
SDK_ROOT="$HOME/Android/Sdk"
IMG_PATH="system-images/android-34/google_apis/x86_64"
ROOTAVD_DIR="/home/yz/Downloads/Telegram Desktop/rootAVD-master"

log_info "=== Android Lab Setup ==="

# 1. Download google_apis image
if [[ ! -d "$SDK_ROOT/$IMG_PATH" ]]; then
	log_info "[1/6] Downloading google_apis system image..."
	sdkmanager "system-images;android-34;google_apis;x86_64"
else
	print_success "[1/6] google_apis image already present"
fi

# 2. Create AVD
if [[ ! -d "$HOME/.android/avd/${AVD_NAME}.avd" ]]; then
	log_info "[2/6] Creating ${AVD_NAME}..."
	echo "no" | avdmanager create avd -n "$AVD_NAME" \
		-k "system-images;android-34;google_apis;x86_64" \
		--force --device "pixel_4"
else
	print_success "[2/6] ${AVD_NAME} already exists"
fi

# 3. Start emulator for rooting
log_info "[3/6] Starting emulator for rootAVD..."
pkill -f "qemu-system" 2>/dev/null || true
sleep 2
rm -f "$HOME/.android/avd/${AVD_NAME}.avd/"*.lock

emulator -avd "$AVD_NAME" -no-window -no-audio -no-snapshot \
	-gpu swiftshader_indirect -memory 4096 -no-metrics &
EMU_PID=$!

log_info "Waiting for boot..."
adb wait-for-device
while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do sleep 5; done
print_success "Booted!"

# 4. Root with rootAVD
log_info "[4/6] Rooting with Magisk via rootAVD..."
cd "$ROOTAVD_DIR"
bash rootAVD.sh "system-images/android-34/google_apis/x86_64/ramdisk.img"

log_info "Waiting for rootAVD to finish..."
sleep 90

# Restart emulator with rooted ramdisk
kill "$EMU_PID" 2>/dev/null || true
sleep 5
emulator -avd "$AVD_NAME" -no-window -no-audio -no-snapshot \
	-gpu swiftshader_indirect -memory 4096 -no-metrics &
adb wait-for-device
while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do sleep 5; done

# Configure Magisk auto-grant
adb root
sleep 2
adb shell 'su 0 sqlite3 /data/adb/magisk.db "INSERT OR REPLACE INTO policies (uid, policy, until, logging, notification) VALUES (2000, 2, 0, 1, 1);"' 2>/dev/null || true
print_success "Root configured"

# 5. Push frida-server
log_info "[5/6] Setting up frida-server..."
FRIDA_VER=$(nix-shell -p frida-tools --run "frida --version")
if [[ ! -f /tmp/frida-server ]]; then
	curl -L -o /tmp/frida-server.xz \
		"https://github.com/frida/frida/releases/download/${FRIDA_VER}/frida-server-${FRIDA_VER}-android-x86_64.xz"
	xz -d /tmp/frida-server.xz
	chmod +x /tmp/frida-server
fi
adb push /tmp/frida-server /data/local/tmp/
adb shell "su -c 'chmod 755 /data/local/tmp/frida-server'"
print_success "frida-server pushed"

# 6. Install MITM cert via Magisk module
log_info "[6/6] Installing MITM cert..."
HASH=$(openssl x509 -inform PEM -subject_hash_old -in "$HOME/.mitmproxy/mitmproxy-ca-cert.pem" | head -1)
adb push "$HOME/.mitmproxy/mitmproxy-ca-cert.pem" "/data/local/tmp/${HASH}.0"
adb shell "su -c '
  mkdir -p /data/adb/modules/mitmproxy_cert/system/etc/security/cacerts
  cp /data/local/tmp/${HASH}.0 /data/adb/modules/mitmproxy_cert/system/etc/security/cacerts/
  chmod 644 /data/adb/modules/mitmproxy_cert/system/etc/security/cacerts/${HASH}.0
  echo -e \"id=mitmproxy_cert\nname=MITMProxy CA Certificate\nversion=v1.0\nversionCode=1\nauthor=security-test\ndescription=Installs mitmproxy CA cert\" > /data/adb/modules/mitmproxy_cert/module.prop
'"
print_success "MITM cert module installed"

# Reboot to activate
log_info "Rebooting to activate Magisk modules..."
adb reboot
sleep 30
adb wait-for-device
while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do sleep 5; done

# Verify
echo ""
print_success "=== SETUP COMPLETE ==="
echo "Root: $(adb shell 'su -c id' 2>/dev/null)"
echo "Frida: $(adb shell 'su -c pgrep frida-server' 2>/dev/null || echo 'start with: adb shell su -c /data/local/tmp/frida-server')"
echo "MITM cert: $(adb shell "ls /system/etc/security/cacerts/ | grep $HASH" 2>/dev/null || echo 'reboot needed')"
