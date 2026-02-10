#!/usr/bin/env bash
# LibreWolf Work Profile - Privacy-hardened browser for work use

set -euo pipefail

PROFILE_DIR="$HOME/.librewolf-work"
USER_JS="$PROFILE_DIR/user.js"

# Create profile directory if it doesn't exist
if [[ ! -d "$PROFILE_DIR" ]]; then
    mkdir -p "$PROFILE_DIR"
    chmod 700 "$PROFILE_DIR"
fi

# Write privacy-hardened user.js
cat > "$USER_JS" <<'EOF'
// LibreWolf Work Profile - Privacy Hardened Configuration

// === Network and DNS ===
user_pref("network.trr.mode", 3);  // TRR (DNS over HTTPS) only
user_pref("network.trr.custom_uri", "https://dns.quad9.net/dns-query");
user_pref("network.gio.supported-protocols", "afs,cifs,ftp,smb,smbc");

// === Tracking Protection ===
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state_ocsp", true);
user_pref("privacy.partition.network_state", true);

// === Telemetry ===
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// === Cookies and Storage ===
user_pref("network.cookie.cookieBehavior", 1);  // Block third-party cookies
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.sessions", true);

// === Security ===
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.window.maxInnerWidth", 1600);
user_pref("privacy.window.maxInnerHeight", 900);
user_pref("webgl.disabled", true);
user_pref("privacy.spoof_english", 2);  // Spoof English

// === Extensions and UI ===
user_pref("extensions.autoDisableScopes", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);

// === Safe Browsing ===
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);

// === HTTPS Only ===
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_ever_enabled", true);
EOF

# Launch LibreWolf with the isolated profile
exec librewolf --profile "$PROFILE_DIR" "$@"
