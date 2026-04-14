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
  };

  programs = {
    home-manager.enable = true;
    nix-index.enable = false; # Handled by nix-index-database
    nix-index-database.comma.enable = true;
  };

  # User services (auto-start tray applets)
  services = {
    network-manager-applet.enable = true;
    gnome-keyring.enable = true; # Provides org.freedesktop.secrets for Electron/Element
    # easyeffects disabled: 8.0.9 crashes (SIGSEGV in lilv_world_load_plugin_classes)
    # RNNoise noise cancellation is handled by PipeWire filter-chain in nixos-modules/audio.nix
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
