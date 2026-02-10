# Application sandboxing with Firejail and bubblewrap.

{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:

{
  options.mySystem.sandboxing = {
    enable = lib.mkEnableOption "application sandboxing with Firejail and bubblewrap";

    enableUserNamespaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = true;
      description = "Enable unprivileged user namespaces for Firejail and bubblewrap. Required for bubblewrap and modern sandbox features.";
    };

    enableWrappedBinaries = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Firejail's wrapped binaries for automatic sandboxing of common applications (browsers, office suites, etc.).";
    };
  };

  config = lib.mkIf config.mySystem.sandboxing.enable {
    programs.firejail = {
      enable = true;
      wrappedBinaries = lib.mkIf config.mySystem.sandboxing.enableWrappedBinaries {

        # =====================================================================
        # HIGH RISK — Internet-facing apps with large attack surfaces
        # (rendering engines, media codecs, JavaScript execution)
        # =====================================================================

        # Browsers — use upstream profiles (handle NixOS properly via seccomp)
        brave = {
          executable = "${pkgs.lib.getBin pkgs.brave}/bin/brave";
          profile = "${pkgs.firejail}/etc/firejail/brave.profile";
        };

        # LibreWolf upstream profile works on NixOS (seccomp !chroot handles it)
        librewolf = {
          executable = "${pkgs.lib.getBin pkgsStable.librewolf}/bin/librewolf";
          profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
        };

        # Messaging — use upstream profiles
        signal-desktop = {
          executable = "${pkgs.lib.getBin pkgs.signal-desktop-bin}/bin/signal-desktop";
          profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
        };

        telegram-desktop = {
          executable = "${pkgs.lib.getBin pkgs.telegram-desktop}/bin/Telegram";
          profile = "${pkgs.firejail}/etc/firejail/telegram-desktop.profile";
        };

        wire-desktop = {
          executable = "${pkgs.lib.getBin pkgsStable.wire-desktop}/bin/wire-desktop";
          profile = "${pkgs.firejail}/etc/firejail/wire-desktop.profile";
        };

        # Media streaming
        freetube = {
          executable = "${pkgs.lib.getBin pkgs.freetube}/bin/freetube";
          profile = "${pkgs.firejail}/etc/firejail/freetube.profile";
        };

        celluloid = {
          executable = "${pkgs.lib.getBin pkgsStable.celluloid}/bin/celluloid";
          profile = "${pkgs.firejail}/etc/firejail/celluloid.profile";
        };

        # Torrent client
        qbittorrent = {
          executable = "${pkgs.lib.getBin pkgsStable.qbittorrent}/bin/qbittorrent";
          profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
        };

        # =====================================================================
        # MEDIUM RISK — Network-facing or semi-trusted input, smaller surfaces
        # =====================================================================

        # Password manager
        keepassxc = {
          executable = "${pkgs.lib.getBin pkgsStable.keepassxc}/bin/keepassxc";
          profile = "${pkgs.firejail}/etc/firejail/keepassxc.profile";
        };

        # Image viewer
        imv = {
          executable = "${pkgs.lib.getBin pkgsStable.imv}/bin/imv";
          profile = "${pkgs.firejail}/etc/firejail/imv.profile";
        };

        # Office suite
        libreoffice = {
          executable = "${pkgs.lib.getBin pkgsStable.libreoffice-qt6-fresh}/bin/libreoffice";
          profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        };

        # File sharing over Tor
        onionshare-cli = {
          executable = "${pkgs.lib.getBin pkgsStable.onionshare}/bin/onionshare-cli";
          profile = "${pkgs.firejail}/etc/firejail/onionshare-cli.profile";
        };

        # Metadata removal
        metadata-cleaner = {
          executable = "${pkgs.lib.getBin pkgsStable.metadata-cleaner}/bin/metadata-cleaner";
          profile = "${pkgs.firejail}/etc/firejail/metadata-cleaner.profile";
        };

        # System cleaner
        bleachbit = {
          executable = "${pkgs.lib.getBin pkgsStable.bleachbit}/bin/bleachbit";
          profile = "${pkgs.firejail}/etc/firejail/bleachbit.profile";
        };

        # Database browser
        sqlitebrowser = {
          executable = "${pkgs.lib.getBin pkgsStable.sqlitebrowser}/bin/sqlitebrowser";
          profile = "${pkgs.firejail}/etc/firejail/sqlitebrowser.profile";
        };

      };
    };

    # Disable only tor-browser profile (has hardcoded paths incompatible with NixOS)
    # LibreWolf profile works fine - firefox-common includes seccomp !chroot
    environment = {
      etc."firejail/tor-browser.profile".enable = false;

      systemPackages = with pkgs; [
        firejail
        bubblewrap
        squashfsTools
      ];
    };

    boot.kernel.sysctl = lib.mkIf config.mySystem.sandboxing.enableUserNamespaces {
      "kernel.unprivileged_userns_clone" = 1;
      "user.max_user_namespaces" = 256;
    };
  };
}
