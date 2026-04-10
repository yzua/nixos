#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  exit 1
fi

url="$1"

# Convert custom ytmpv:// scheme redirects back to normal YouTube URLs.
case "$url" in
  ytmpv://watch\?v=*)
    url="https://www.youtube.com/watch?v=${url#ytmpv://watch?v=}"
    ;;
  ytmpv://youtu.be/*)
    url="https://youtu.be/${url#ytmpv://youtu.be/}"
    ;;
  ytmpv://https://*)
    url="${url#ytmpv://}"
    ;;
esac

# Channel "videos" pages are not directly playable; open newest upload.
case "$url" in
  */channel/*/videos|*/@*/videos|*/c/*/videos|*/user/*/videos)
    first_video="$(
      yt-dlp --flat-playlist --playlist-end 1 --print webpage_url -- "$url" 2>/dev/null | head -n 1
    )"
    if [[ -n "$first_video" ]]; then
      url="$first_video"
    fi
    ;;
esac

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
(
  __NOTIFY_SEND_BIN__ \
    --app-name="youtube-mpv" \
    --urgency=low \
    --expire-time=3500 \
    "YouTube -> mpv" \
    "Loading in external player..." || true
) &

# Prefer non-AV1 formats to avoid unsupported hardware decode paths.
exec mpv \
  --wayland-app-id=youtube-mpv \
  --hwdec=no \
  --ytdl-format="bestvideo[vcodec!^=av01][height<=1440]+bestaudio/best[vcodec!^=av01][height<=1440]/best" \
  "$url"
