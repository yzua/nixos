# Shared host profile defaults for all mySystem options.

{
  config,
  lib,
  ...
}:

let
  profile = config.mySystem.hostProfile;
  isDesktop = profile == "desktop";
  isLaptop = profile == "laptop";
  mkDefaultTrue = lib.mkDefault true;
  mkDefaultFalse = lib.mkDefault false;
in
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
      cleanup.enable = mkDefaultTrue;
      flatpak.enable = mkDefaultTrue;
      mullvadVpn.enable = mkDefaultTrue;
      tor.enable = mkDefaultTrue;
      i2pd.enable = mkDefaultFalse;
      yggdrasil.enable = mkDefaultFalse;
      dnscryptProxy.enable = mkDefaultTrue;
      printing.enable = mkDefaultTrue;
      virtualisation.enable = mkDefaultTrue;
      nautilus.enable = mkDefaultTrue;
      glance.enable = mkDefaultTrue;
      netdata.enable = mkDefaultTrue;
      nixLd.enable = mkDefaultTrue;
      opensnitch.enable = mkDefaultTrue;
      scrutiny.enable = mkDefaultTrue;
      waydroid.enable = mkDefaultTrue;
      kdeconnect.enable = mkDefaultTrue;
      greetd.enable = mkDefaultTrue;
      nvidia.enable = mkDefaultTrue;
      fwupd.enable = mkDefaultTrue;
      backup.enable = mkDefaultFalse; # Requires restic-password sops secret
      ntfy.enable = mkDefaultTrue;
      observability.enable = mkDefaultTrue;
      loki.enable = mkDefaultTrue;
      systemReport.enable = mkDefaultTrue;
      auditLogging.enable = mkDefaultTrue; # fail2ban does NOT conflict with AppArmor (only auditd does)
      metadataScrubber.enable = mkDefaultTrue; # Auto-strip metadata from user files
      aide.enable = mkDefaultTrue; # Weekly AIDE file integrity monitoring
      secureBoot.enable = mkDefaultTrue; # Secure Boot preparation with sbctl
      vnc.enable = mkDefaultFalse; # On-demand remote access

      # Profile-dependent defaults
      gaming = {
        enable = lib.mkDefault isDesktop;
        enableGamemode = lib.mkDefault isDesktop;
        enableGamescope = lib.mkDefault isDesktop;
      };
      bluetooth = {
        enable = lib.mkDefault isLaptop;
        powerOnBoot = mkDefaultFalse;
      };
    };
    environment.systemPackages = lib.mkDefault [ ];
  };
}
