#!/usr/bin/env bash
# Temporary LibreWolf Tor Profile - Ephemeral Tor browser (profile deleted on exit)

set -euo pipefail

# Create ephemeral profile in tmpfs
PROFILE_DIR=$(mktemp -d -t librewolf-tmp-tor.XXXXXX)
chmod 700 "$PROFILE_DIR"
USER_JS="$PROFILE_DIR/user.js"

# Write Tor-aware privacy configuration
cat > "$USER_JS" <<'EOF'
// LibreWolf Temporary Tor Profile - Ephemeral session through Tor

// === Proxy Configuration ===
user_pref("network.proxy.type", 1);  // Manual proxy configuration
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 9050);
user_pref("network.proxy.socks_version", 5);
user_pref("network.proxy.socks_remote_dns", true);  // DNS through Tor

// === Proxy DNS over HTTPS ===
user_pref("network.trr.mode", 5);  // Disabled when using proxy
user_pref("network.trr.custom_uri", "");

// === WebRTC IP Leak Prevention ===
user_pref("media.peerconnection.enabled", false);
user_pref("media.navigator.enabled", false);
user_pref("media.webspeech.recognition.enable", false);

// === Tracking Protection (Enhanced for Tor) ===
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state_ocsp", true);
user_pref("privacy.partition.network_state", true);

// === Canvas Fingerprinting Protection ===
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.window.maxInnerWidth", 1366);
user_pref("privacy.window.maxInnerHeight", 768);

// === WebGL Disabled ===
user_pref("webgl.disabled", true);
user_pref("webgl.enable-webgl2", false);

// === Locale Spoofing ===
user_pref("privacy.spoof_english", 2);
user_pref("javascript.use_us_english_locale", true);

// === Telemetry Disabled ===
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// === Storage and Cookies (Ephemeral) ===
user_pref("network.cookie.cookieBehavior", 1);
user_pref("browser.privatebrowsing.autostart", true);  // Private browsing mode

// === Security ===
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);

// === Extensions ===
user_pref("extensions.autoDisableScopes", 0);

// === UI ===
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);

// === No Session Restore ===
user_pref("browser.sessionstore.enabled", false);
EOF

# Check if Tor is running before launching (system Tor on 9050, Tor Browser on 9150)
if ! nc -z 127.0.0.1 9050 2>/dev/null && ! nc -z 127.0.0.1 9150 2>/dev/null; then
    notify-send "Tor Not Running" "Tor SOCKS5 proxy (port 9050/9150) is not available. Please start Tor service." --icon=dialog-warning 2>/dev/null || true
    rm -rf "$PROFILE_DIR"
    exit 1
fi

# Launch LibreWolf with ephemeral profile
# Clean up profile directory on exit
trap 'rm -rf "$PROFILE_DIR"' EXIT

exec librewolf --profile "$PROFILE_DIR" "$@"
