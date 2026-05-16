# Tailscale private mesh networking for remote access from trusted devices.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.tailscale;
  mullvadExclude = "/run/wrappers/bin/mullvad-exclude";
in
{
  options.mySystem.tailscale = {
    enable = lib.mkEnableOption "Tailscale private mesh networking";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      extraSetFlags = [
        "--accept-dns=false"
        "--accept-routes=false"
        "--exit-node="
        "--netfilter-mode=nodivert"
      ];
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    environment.systemPackages = [ pkgs.tailscale ];

    systemd.services.tailscaled = lib.mkIf config.mySystem.mullvadVpn.enable {
      wants = [ "mullvad-daemon.service" ];
      after = [ "mullvad-daemon.service" ];
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${mullvadExclude} ${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --tun tailscale0"
      ];
    };
  };
}
