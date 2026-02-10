# Home Manager entry point.
{
  homeStateVersion,
  user,
  ...
}:

{
  imports = [
    ./modules
    ./packages
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  home.sessionVariables = {
    # Wayland/Qt integration
    QT_QPA_PLATFORM = "wayland;xcb";
    DISABLE_QT5_COMPAT = "0";
    CALIBRE_USE_DARK_PALETTE = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";

    # === Telemetry & tracking opt-outs ===
    ADBLOCK = "1";
    ASTRO_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    CHECKPOINT_DISABLE = "1";
    DISABLE_OPENCOLLECTIVE = "1";
    DO_NOT_TRACK = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    GOTELEMETRY = "off";
    HOMEBREW_NO_ANALYTICS = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    NPM_CONFIG_UPDATE_NOTIFIER = "false";
    NUXT_TELEMETRY_DISABLED = "1";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    SAM_CLI_TELEMETRY = "0";
    SENTRY_DSN = "";
    STRIPE_CLI_TELEMETRY_OPTOUT = "1";
  };

  programs = {
    home-manager.enable = true;
    nix-index.enable = false; # Handled by nix-index-database
    nix-index-database.comma.enable = true;
  };

  # User services (auto-start tray applets and audio pipeline)
  services = {
    network-manager-applet.enable = true;
    easyeffects.enable = true;
  };

  # Desktop entries for firejail-wrapped binaries
  xdg.desktopEntries = {
    "org.telegram.desktop" = {
      name = "Telegram Desktop";
      exec = "telegram-desktop -- %U";
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
      exec = "brave %U";
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
  };

  # Stylix sets GTK theme but not dconf color-scheme key — without this,
  # GTK4/libadwaita apps default to light mode (dark text on dark background).
  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      recent-files-max-age = 0;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = 7; # days retention for trash/temp (uint32)
    };
  };
}
