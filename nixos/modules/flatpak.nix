# Flatpak sandboxed application distribution with Flathub.
{ config, lib, ... }:

{
  options.mySystem.flatpak = {
    enable = lib.mkEnableOption "Flatpak support for sandboxed applications";
  };

  config = lib.mkIf config.mySystem.flatpak.enable {
    services.flatpak.enable = true;

    systemd = {
      # PRIVACY: Share host network so Flatpak uses system DNS/VPN
      tmpfiles.rules = [
        "d /etc/flatpak/overrides 0755 root root -"
        ''f /etc/flatpak/overrides/global 0644 root root - [Context]\nshared=network;\n''
      ];

      services.add-flathub = {
        description = "Add Flathub remote";
        wantedBy = [ ]; # Deferred — started by timer after boot to avoid network wait
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "dnscrypt-proxy.service"
          "flatpak-system.service"
        ];
        path = [ config.services.flatpak.package ];
        script = ''
          flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 10;
          RestartSteps = 3; # Required when RestartMaxDelaySec is set
          RestartMaxDelaySec = 60;
          # SECURITY: Systemd hardening directives
          PrivateTmp = true;
          ProtectHome = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
        };
      };

      # Start Flathub registration 2 minutes after boot (needs network + DNS)
      timers.add-flathub-deferred = {
        description = "Deferred Flathub registration";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "120s";
          Unit = "add-flathub.service";
        };
      };
    };
  };
}
