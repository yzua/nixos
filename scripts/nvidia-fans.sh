#!/usr/bin/env bash
# nvidia-fans.sh - Set NVIDIA GPU fan speed manually
# Usage: nvidia-fans <speed>
# Example: nvidia-fans 40  (sets fans to 40%)

set -euo pipefail

# Check if fan speed argument is provided
if [[ -z "${1:-}" ]]; then
  echo "Error: Fan speed argument required" >&2
  echo "Usage: nvidia-fans <speed>" >&2
  echo "Example: nvidia-fans 40" >&2
  exit 1
fi

FAN_SPEED="$1"

# Validate fan speed is a number between 0 and 100
if ! [[ "$FAN_SPEED" =~ ^[0-9]+$ ]] || (( FAN_SPEED < 0 || FAN_SPEED > 100 )); then
  echo "Error: Fan speed must be a number between 0 and 100" >&2
  exit 1
fi

# Get DISPLAY (default to :0 if not set)
DISPLAY="${DISPLAY:-:0}"

# Get XAUTHORITY (default to empty if not set, nvidia-settings will find it)
XAUTHORITY="${XAUTHORITY:-}"

# Enable manual fan control and set fan speed (suppress all output)
if [[ -n "$XAUTHORITY" ]]; then
  sudo -E env "DISPLAY=$DISPLAY" "XAUTHORITY=$XAUTHORITY" \
    nvidia-settings -a "[gpu:0]/GPUFanControlState=1" >/dev/null 2>&1

  sudo -E env "DISPLAY=$DISPLAY" "XAUTHORITY=$XAUTHORITY" \
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=$FAN_SPEED" >/dev/null 2>&1

  sudo -E env "DISPLAY=$DISPLAY" "XAUTHORITY=$XAUTHORITY" \
    nvidia-settings -a "[fan:1]/GPUTargetFanSpeed=$FAN_SPEED" >/dev/null 2>&1
else
  sudo nvidia-settings -c "$DISPLAY" \
    -a "[gpu:0]/GPUFanControlState=1" >/dev/null 2>&1

  sudo nvidia-settings -c "$DISPLAY" \
    -a "[fan:0]/GPUTargetFanSpeed=$FAN_SPEED" >/dev/null 2>&1

  sudo nvidia-settings -c "$DISPLAY" \
    -a "[fan:1]/GPUTargetFanSpeed=$FAN_SPEED" >/dev/null 2>&1
fi
