#!/usr/bin/env bash
# LibreWolf Work Tor Profile - LibreWolf routed through Tor SOCKS5 proxy

set -euo pipefail

PROFILE_DIR="$HOME/.librewolf-work-tor"
USER_JS="$PROFILE_DIR/user.js"

# Create profile directory if it doesn't exist
if [[ ! -d "$PROFILE_DIR" ]]; then
    mkdir -p "$PROFILE_DIR"
    chmod 700 "$PROFILE_DIR"
fi

# Write Tor-aware privacy configuration
cat > "$USER_JS" <<'EOF'
// LibreWolf Work Tor Profile - Routed through Tor SOCKS5 Proxy

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

// === Storage and Cookies ===
user_pref("network.cookie.cookieBehavior", 1);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);

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
EOF

# Check if Tor is running before launching (system Tor on 9050, Tor Browser on 9150)
if ! nc -z 127.0.0.1 9050 2>/dev/null && ! nc -z 127.0.0.1 9150 2>/dev/null; then
    notify-send "Tor Not Running" "Tor SOCKS5 proxy (port 9050/9150) is not available. Please start Tor service." --icon=dialog-warning 2>/dev/null || true
    exit 1
fi

# Launch LibreWolf with the Tor-aware profile
exec librewolf --profile "$PROFILE_DIR" "$@"
