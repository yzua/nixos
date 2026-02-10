# NetworkManager with MAC randomization, DNS delegation, and DHCP leak prevention.
{ lib, ... }:

{
  networking = {
    enableIPv6 = false; # Prevent leak vectors that bypass VPN tunnels

    networkmanager = {
      enable = true;
      dns = "none"; # DNSCrypt-Proxy handles DNS

      # PRIVACY: Randomize MAC addresses
      wifi = {
        macAddress = "random";
        scanRandMacAddress = true;
      };
      ethernet.macAddress = "random";

      # PRIVACY: Prevent hostname/identifier leaks via DHCP
      settings = {
        connectivity.enabled = false; # Leaks IP and timing patterns
        "connection" = {
          "ipv4.dhcp-send-hostname" = false;
          "ipv6.dhcp-send-hostname" = false;
          "connection.stable-id" = "\${CONNECTION}/\${BOOT}"; # Rotate per boot
        };
        "device"."wifi.scan-rand-mac-address" = true;
      };
    };
  };

  # mkForce needed — Mullvad VPN module tries to enable resolved
  # DNS chain: Apps -> dnscrypt-proxy (127.0.0.1:53) -> Mullvad tunnel -> resolver
  services.resolved.enable = lib.mkForce false;
}
