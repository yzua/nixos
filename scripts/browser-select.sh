#!/usr/bin/env bash
set -euo pipefail

url="${1:-}"

# If we are not inside a terminal, spawn ourselves inside foot so GUI prompts work.
if [[ -z "${TMUX:-}" && -z "${KITTY_WINDOW_ID:-}" && -z "${TERM:-}" ]]; then
  exec foot --app-id=browser-select "${HOME}/.local/bin/browser-select" "$@"
fi

browser_entries=(
  "LibreWolf Personal|${HOME}/.local/bin/librewolf-personal|🦊"
  "LibreWolf Work|${HOME}/.local/bin/librewolf-work|🦊"
  "LibreWolf Banking|${HOME}/.local/bin/librewolf-banking|🦊"
  "LibreWolf Shopping|${HOME}/.local/bin/librewolf-shopping|🦊"
  "LibreWolf Illegal|${HOME}/.local/bin/librewolf-illegal|🦊"
  "LibreWolf I2P|${HOME}/.local/bin/librewolf-i2pd|🦊"
  "Brave|${HOME}/.local/bin/brave-proxy|🦁"
)

if [[ -n "$url" ]]; then
  case "$url" in
    *music.youtube.com/*)
      browser_entries+=("MPV (YouTube)|${HOME}/.local/bin/youtube-mpv|🎬")
      ;;
    *youtube.com/*|*youtu.be/*)
      browser_entries+=("MPV (YouTube)|${HOME}/.local/bin/youtube-mpv|🎬")
      ;;
  esac
fi

declare -A launchers
options=()

for entry in "${browser_entries[@]}"; do
  IFS='|' read -r name launcher icon <<< "$entry"
  label="$name"
  if [[ -n "$icon" ]]; then
    label="$icon $name"
  fi
  options+=("$label")
  launchers["$label"]="$launcher"
done

prompt="Launch browser"
[[ -n "$url" ]] && prompt="Open URL with"

wofi_args=(
  --dmenu
  --prompt "$prompt"
  --width 640
  --lines 8
  --hide-scroll
  --location top
)

[[ -n "$url" ]] && wofi_args+=(--header "$url")

mapfile -t sorted < <(printf '%s\n' "${options[@]}" | sort)

selection=$(printf '%s\n' "${sorted[@]}" | wofi "${wofi_args[@]}")

[[ -z "$selection" ]] && exit 0

launcher_cmd="${launchers[$selection]}"

if [[ -n "$url" ]]; then
  exec "$launcher_cmd" "$url"
else
  exec "$launcher_cmd"
fi
