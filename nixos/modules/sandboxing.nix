# Application sandboxing with Firejail and bubblewrap.

{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:

let
  mesaEglVendorFile = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  mesaEglFirejailArg = "--env=__EGL_VENDOR_LIBRARY_FILENAMES=${mesaEglVendorFile}";
  braveLauncherWrapped = pkgs.writeShellScript "brave-with-basic-password-store" ''
    # Keep Brave launch stable under current NVIDIA + Firejail setup.

    exec ${pkgs.lib.getBin pkgs.brave}/bin/brave \
      --password-store=basic \
      --disable-gpu \
      --proxy-server="socks5://se-mma-wg-socks5-004.relays.mullvad.net:1080" \
      "$@"
  '';
in
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
        # Force Mesa EGL inside sandbox — firejail strips session env vars,
        # so the system-wide override in nvidia.nix doesn't reach sandboxed apps.
        brave = {
          executable = "${braveLauncherWrapped}";
          profile = "${pkgs.firejail}/etc/firejail/brave.profile";
          extraArgs = [ mesaEglFirejailArg ];
        };

        # LibreWolf upstream profile works on NixOS (seccomp !chroot handles it)
        # Force Mesa EGL inside sandbox — firejail strips session env vars,
        # so the system-wide override in nvidia.nix doesn't reach sandboxed apps.
        librewolf = {
          executable = "${pkgs.lib.getBin pkgsStable.librewolf}/bin/librewolf";
          profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
          extraArgs = [ mesaEglFirejailArg ];
        };

        # Messaging — use upstream profiles
        signal-desktop = {
          executable = "${pkgs.lib.getBin pkgs.signal-desktop}/bin/signal-desktop";
          profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
        };

        telegram-desktop = {
          executable = "${pkgs.lib.getBin pkgs.telegram-desktop}/bin/Telegram";
          profile = "${pkgs.firejail}/etc/firejail/telegram-desktop.profile";
        };

        # Discord client (Vencord plugins execute arbitrary JS)
        vesktop = {
          executable = "${pkgs.lib.getBin pkgs.vesktop}/bin/vesktop";
          profile = "${pkgs.firejail}/etc/firejail/discord.profile";
        };

        # Torrent client
        qbittorrent = {
          executable = "${pkgs.lib.getBin pkgsStable.qbittorrent}/bin/qbittorrent";
          profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
        };

        # =====================================================================
        # MEDIUM RISK — Network-facing or semi-trusted input, smaller surfaces
        # =====================================================================

        # KeePassXC excluded from firejail — needs SSH agent socket at
        # $XDG_RUNTIME_DIR, D-Bus for Secret Service, and native messaging
        # for browser integration. It encrypts its own database already.

      };
    };

    # Disable only tor-browser profile (has hardcoded paths incompatible with NixOS)
    # LibreWolf profile works fine - firefox-common includes seccomp !chroot
    environment = {
      etc = {
        "firejail/tor-browser.profile".enable = false;

        # KeePassXC browser integration — whitelist the browser socket so
        # keepassxc-proxy (spawned inside the firejail sandbox) can reach KeePassXC.
        # Whitelists both the socket, the symlink, and the legacy kpxc_server path.
        "firejail/brave.local".text = ''
          noblacklist ''${RUNUSER}/app
          whitelist ''${RUNUSER}/app/org.keepassxc.KeePassXC
          whitelist ''${RUNUSER}/kpxc_server
          whitelist ''${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer
        '';

        # Apply same KeePassXC whitelist to LibreWolf
        "firejail/librewolf.local".text = ''
          noblacklist ''${RUNUSER}/app
          whitelist ''${RUNUSER}/app/org.keepassxc.KeePassXC
          whitelist ''${RUNUSER}/kpxc_server
          whitelist ''${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer
        '';

        # Telegram drag-and-drop support for files outside ~/Downloads.
        "firejail/telegram.local".text = ''
          noblacklist ''${HOME}/Documents
          noblacklist ''${HOME}/Pictures
          noblacklist ''${HOME}/Videos
          noblacklist ''${HOME}/Music
          noblacklist ''${HOME}/Desktop

          whitelist ''${HOME}/Documents
          whitelist ''${HOME}/Pictures
          whitelist ''${HOME}/Videos
          whitelist ''${HOME}/Music
          whitelist ''${HOME}/Desktop
        '';

        # FreeTube (Electron 38+) needs system D-Bus access in sandbox.
        "firejail/freetube.local".text = ''
          ignore dbus-system none
        '';
      };

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
