#!/usr/bin/env bash
# Brave Personal Profile - Brave browser with Mullvad VPN kill-switch.

set -euo pipefail

PROFILE_DIR="$HOME/.brave-personal"
PID_FILE="/tmp/browser-personal-monitor.pid"
VPN_CHECK_INTERVAL=5

if [[ ! -d "$PROFILE_DIR" ]]; then
    mkdir -p "$PROFILE_DIR"
    chmod 700 "$PROFILE_DIR"
fi

is_vpn_connected() {
    mullvad status 2>/dev/null | grep -q "Connected"
}

kill_browser() {
    pkill -f "brave.*--user-data-dir=$PROFILE_DIR" 2>/dev/null || true
}

cleanup() {
    if [[ -f "$PID_FILE" ]]; then
        local monitor_pid
        monitor_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$monitor_pid" ]] && kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
}

trap cleanup EXIT INT TERM

if ! is_vpn_connected; then
    notify-send "Mullvad VPN" "Not connected. Attempting to connect..." \
        --icon=dialog-warning 2>/dev/null || true
    mullvad connect 2>/dev/null || true

    # Wait up to 15 seconds for connection
    for _ in $(seq 1 15); do
        if is_vpn_connected; then
            break
        fi
        sleep 1
    done

    if ! is_vpn_connected; then
        notify-send "Mullvad VPN" "Failed to connect. Browser not launched." \
            --icon=dialog-error 2>/dev/null || true
        exit 1
    fi
fi

notify-send "Mullvad VPN" "Connected. Launching personal browser." \
    --icon=dialog-information 2>/dev/null || true

# Background VPN monitor — kills browser if VPN drops
(
    while true; do
        sleep "$VPN_CHECK_INTERVAL"
        if ! is_vpn_connected; then
            notify-send "VPN DISCONNECTED" "Killing personal browser to protect your IP." \
                --icon=dialog-error 2>/dev/null || true
            kill_browser
            break
        fi
    done
) &
echo $! > "$PID_FILE"

brave --user-data-dir="$PROFILE_DIR" "$@" || true

cleanup
