# Desktop entries and launcher wrapper scripts for desktop applications.
{
  pkgs,
  user,
  ...
}:

let
  constants = import ../../../shared/constants.nix;

  mkDesktopEntry =
    {
      name,
      exec,
      icon,
      comment,
      categories,
      mimeType ? null,
    }:
    {
      inherit
        name
        exec
        icon
        comment
        categories
        ;
    }
    // (if mimeType == null then { } else { inherit mimeType; });

  librewolfDesktopProfiles = import ./librewolf/_profiles.nix { inherit constants; };

  librewolfDesktopEntries = builtins.listToAttrs (
    map (profile: {
      name = "librewolf-${profile.name}";
      value = mkDesktopEntry {
        name = "LibreWolf ${profile.label}";
        exec = "/home/${user}/.local/bin/librewolf-${profile.name} %U";
        icon = "librewolf";
        inherit (profile) comment;
        categories = [ "Network" ];
      };
    }) librewolfDesktopProfiles
  );
in

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
        exec ${pkgs.element-desktop}/bin/element-desktop --password-store=gnome-libsecret "$@" >> "$main_log_file" 2>&1
      '';
    };

    ".local/bin/browser-select" = {
      executable = true;
      text = builtins.readFile ../../../scripts/apps/browser-select.sh;
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
        (
          ${pkgs.libnotify}/bin/notify-send \
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
      '';
    };

    ".local/bin/xdg-open" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [[ $# -gt 0 ]]; then
          url="$1"
          case "$url" in
            http://*|https://*)
              # Interactive browser selection for HTTP/HTTPS URLs
              exec /home/${user}/.local/bin/browser-select "$url"
              ;;
            ytmpv://*)
              # Custom YouTube-to-mpv protocol
              exec /home/${user}/.local/bin/youtube-mpv "$url"
              ;;
          esac
        fi

        exec /run/current-system/sw/bin/xdg-open "$@"
      '';
    };
  };

  home.packages = [
    pkgs.wofi
  ];

  xdg.desktopEntries = {
    "youtube-mpv" = mkDesktopEntry {
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
    "element-desktop" = mkDesktopEntry {
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

    # === Brave ===
    "brave-proxy" = mkDesktopEntry {
      name = "Brave";
      exec = "/home/${user}/.local/bin/brave-proxy %U";
      icon = "brave";
      comment = "Brave with Finland proxy";
      categories = [ "Network" ];
    };
  }
  // librewolfDesktopEntries;
}
