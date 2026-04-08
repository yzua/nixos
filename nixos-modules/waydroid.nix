# Waydroid Android emulation via LXC containers.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.waydroid = {
    enable = lib.mkEnableOption "Waydroid Android emulation (LXC container, requires Wayland)";
  };

  config = lib.mkIf config.mySystem.waydroid.enable {
    # Enable Waydroid container service with nftables-patched package
    # (standard waydroid uses legacy iptables which fails on modern kernels)
    virtualisation.waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };

    # PRIVACY: Force Waydroid to use host's DNSCrypt-Proxy
    environment.etc."waydroid-extra/waydroid_base.prop".text = ''
      net.dns1=127.0.0.1
      persist.waydroid.disable_ipv6=true
    '';

    # Ensure waydroid system user exists so firewall rules can reference it.
    users.users.waydroid = {
      isSystemUser = true;
      group = "waydroid";
    };
    users.groups.waydroid = { };

    # PRIVACY: Restrict Waydroid to VPN tunnel + local DNS only.
    # Uses -I (insert) so these evaluate BEFORE the kill switch -A rules in firewall.nix.
    # Chain order: ACCEPT waydroid→localhost → ACCEPT waydroid→wg+ → DROP waydroid → [kill switch rules]
    networking.firewall.extraCommands = ''
      iptables -I OUTPUT -m owner --uid-owner waydroid -j DROP
      iptables -I OUTPUT -m owner --uid-owner waydroid -o wg+ -j ACCEPT
      iptables -I OUTPUT -m owner --uid-owner waydroid -d 127.0.0.1 -j ACCEPT
    '';
  };
}
