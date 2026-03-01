# Desktop entries and launcher wrapper scripts for desktop applications.
{ user, ... }:

{
  home.file.".local/bin/element-desktop-keyring" = {
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

  xdg.desktopEntries = {
    "org.telegram.desktop" = {
      name = "Telegram Desktop";
      exec = "/run/current-system/sw/bin/telegram-desktop -- %U";
      icon = "telegram";
      comment = "Official Telegram Desktop client (firejail-wrapped)";
      categories = [
        "Chat"
        "Network"
        "InstantMessaging"
      ];
      mimeType = [ "x-scheme-handler/tg" ];
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
