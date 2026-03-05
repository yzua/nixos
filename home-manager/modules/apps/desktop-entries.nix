# Desktop entries and launcher wrapper scripts for desktop applications.
{
  pkgs,
  user,
  ...
}:

{
  home.file = {
    ".local/bin/element-desktop-keyring" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        log_file="''${XDG_CACHE_HOME:-$HOME/.cache}/element-desktop-url-handler.log"
        main_log_file="''${XDG_CACHE_HOME:-$HOME/.cache}/element-desktop-main.log"
        {
          printf '%s ' "$(date --iso-8601=seconds)"
          printf '%q ' "$@"
          printf '\n'
        } >> "$log_file"

        export ELECTRON_ENABLE_LOGGING=1
        exec element-desktop --password-store=gnome-libsecret "$@" >> "$main_log_file" 2>&1
      '';
    };

    ".local/bin/telegram-desktop-quiet" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        log_file="''${XDG_STATE_HOME:-$HOME/.local/state}/telegram-desktop.log"
        mkdir -p "$(dirname "$log_file")"

        # Telegram currently emits frequent Qt paint warnings on Wayland.
        # Keep a local log file while avoiding user-journal spam.
        exec /run/current-system/sw/bin/telegram-desktop "$@" >> "$log_file" 2>&1
      '';
    };

    ".local/bin/youtube-mpv" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [[ $# -lt 1 ]]; then
          exit 1
        fi

        url="$1"

        # Convert custom ytmpv:// scheme redirects back to normal YouTube URLs.
        case "$url" in
          ytmpv://watch\?v=*)
            url="https://www.youtube.com/watch?v=''${url#ytmpv://watch?v=}"
            ;;
          ytmpv://youtu.be/*)
            url="https://youtu.be/''${url#ytmpv://youtu.be/}"
            ;;
          ytmpv://https://*)
            url="''${url#ytmpv://}"
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

        export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus}"
        ${pkgs.libnotify}/bin/notify-send \
          --app-name="youtube-mpv" \
          --urgency=low \
          --expire-time=3500 \
          "YouTube -> mpv" \
          "Loading in external player..." || true

        # Prefer non-AV1 formats to avoid unsupported hardware decode paths.
        exec mpv \
          --wayland-app-id=youtube-mpv \
          --hwdec=no \
          --ytdl-format="bestvideo[vcodec!^=av01][height<=1440]+bestaudio/best[vcodec!^=av01][height<=1440]/best" \
          "$url"
      '';
    };

    ".local/bin/xdg-open" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [[ $# -gt 0 ]]; then
          case "$1" in
            https://youtube.com/*|http://youtube.com/*|https://www.youtube.com/*|http://www.youtube.com/*|https://m.youtube.com/*|http://m.youtube.com/*|https://music.youtube.com/*|http://music.youtube.com/*|https://youtu.be/*|http://youtu.be/*)
              exec /home/${user}/.local/bin/youtube-mpv "$1"
              ;;
          esac
        fi

        exec /run/current-system/sw/bin/xdg-open "$@"
      '';
    };
  };

  xdg.desktopEntries = {
    "org.telegram.desktop" = {
      name = "Telegram Desktop";
      exec = "/home/${user}/.local/bin/telegram-desktop-quiet -- %U";
      icon = "telegram";
      comment = "Official Telegram Desktop client (firejail-wrapped)";
      categories = [
        "Chat"
        "Network"
        "InstantMessaging"
      ];
      mimeType = [ "x-scheme-handler/tg" ];
    };
    "youtube-mpv" = {
      name = "YouTube MPV";
      exec = "/home/${user}/.local/bin/youtube-mpv %U";
      icon = "mpv";
      comment = "Open YouTube links in mpv";
      categories = [
        "AudioVideo"
        "Player"
      ];
      mimeType = [ "x-scheme-handler/ytmpv" ];
    };
    "brave-browser" = {
      name = "Brave Web Browser";
      exec = "/run/current-system/sw/bin/brave %U";
      icon = "brave-browser";
      comment = "Brave Web Browser (firejail-wrapped)";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
    "io.github.celluloid_player.Celluloid" = {
      name = "Celluloid";
      exec = "/run/current-system/sw/bin/celluloid %U";
      icon = "io.github.celluloid_player.Celluloid";
      comment = "GTK video player powered by mpv (firejail-wrapped)";
      categories = [
        "AudioVideo"
        "Video"
        "Player"
        "GTK"
      ];
      mimeType = [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/mpeg"
        "video/ogg"
        "video/x-msvideo"
        "video/mp2t"
        "video/x-flv"
        "audio/mpeg"
        "audio/ogg"
        "audio/flac"
      ];
    };
    "element-desktop" = {
      name = "Element";
      exec = "/home/${user}/.local/bin/element-desktop-keyring %u";
      icon = "element-desktop";
      comment = "Matrix client with libsecret keyring backend";
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      mimeType = [
        "x-scheme-handler/element"
        "x-scheme-handler/io.element.desktop"
        "x-scheme-handler/matrix"
      ];
    };
    "libreoffice-startcenter" = {
      name = "LibreOffice";
      exec = "/run/current-system/sw/bin/libreoffice %U";
      icon = "libreoffice-startcenter";
      comment = "Office suite (firejail-wrapped)";
      categories = [
        "Office"
      ];
      mimeType = [
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/msword"
        "application/vnd.ms-excel"
        "application/vnd.ms-powerpoint"
        "application/rtf"
      ];
    };
  };
}
