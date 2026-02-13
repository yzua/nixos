# Shared host profile defaults for all mySystem options.
{
  config,
  lib,
  ...
}:

{
  options.mySystem.hostProfile = lib.mkOption {
    type = lib.types.enum [
      "desktop"
      "laptop"
    ];
    example = "desktop";
    description = "Host profile type. Determines default values for hardware-dependent options like gaming and bluetooth.";
  };

  config = {
    mySystem = {
      sandboxing = {
        enable = lib.mkDefault true;
        enableUserNamespaces = lib.mkDefault true;
        enableWrappedBinaries = lib.mkDefault true;
      };
      cleanup.enable = lib.mkDefault true;
      flatpak.enable = lib.mkDefault true;
      mullvadVpn.enable = lib.mkDefault true;
      tor.enable = lib.mkDefault true;
      dnscryptProxy.enable = lib.mkDefault true;
      printing.enable = lib.mkDefault true;
      virtualisation.enable = lib.mkDefault true;
      nautilus.enable = lib.mkDefault true;
      glance.enable = lib.mkDefault true;
      netdata.enable = lib.mkDefault true;
      nixLd.enable = lib.mkDefault true;
      opensnitch.enable = lib.mkDefault true;
      scrutiny.enable = lib.mkDefault true;
      waydroid.enable = lib.mkDefault true;
      greetd.enable = lib.mkDefault true;
      nvidia.enable = lib.mkDefault true;
      fwupd.enable = lib.mkDefault true;
      backup.enable = lib.mkDefault false; # Requires restic-password sops secret
      ntfy.enable = lib.mkDefault true;
      observability.enable = lib.mkDefault true;
      loki.enable = lib.mkDefault true;
      systemReport.enable = lib.mkDefault true;
      auditLogging.enable = lib.mkDefault true; # fail2ban does NOT conflict with AppArmor (only auditd does)

      # Profile-dependent defaults
      gaming = {
        enable = lib.mkDefault (config.mySystem.hostProfile == "desktop");
        enableGamescope = lib.mkDefault (config.mySystem.hostProfile == "desktop");
      };
      bluetooth = {
        enable = lib.mkDefault (config.mySystem.hostProfile == "laptop");
        powerOnBoot = lib.mkDefault false;
      };
    };

    programs.gamemode.enable = lib.mkDefault false;
    environment.systemPackages = lib.mkDefault [ ];
  };
}
