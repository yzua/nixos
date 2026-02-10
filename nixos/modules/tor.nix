# Tor SOCKS proxy and onion routing.
{ config, lib, ... }:

{
  options.mySystem.tor = {
    enable = lib.mkEnableOption "Tor service for privacy and anonymity";
  };

  config = lib.mkIf config.mySystem.tor.enable {
    # Reduce bootstrap failures by waiting for VPN tunnel + DNS to be ready.
    # Without this, Tor retries ~34 relays during boot before succeeding.
    systemd.services.tor = {
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "mullvad-daemon.service"
        "dnscrypt-proxy.service"
      ];
    };

    services.tor = {
      enable = true;
      torsocks.enable = true;
      client.enable = true;

      settings = {
        DNSPort = [
          {
            addr = "127.0.0.1";
            port = 9053;
          }
        ];
        AutomapHostsOnResolve = true;
        AutomapHostsSuffixes = [
          ".onion"
          ".exit"
          ".noconnect"
        ];

        # Only use exit nodes in safe jurisdictions
        ExitNodes = "{de},{nl},{ch},{fi},{is},{ro}";

        # Disable IPv6 for better anonymity
        IPv6Exit = false;

        # Non-strict: prefer these exit countries but fall back to others if unavailable.
        # StrictNodes = 1 would shrink anonymity set and break Tor if preferred exits are down.
        StrictNodes = 0;

        # Reduce fingerprinting
        UseEntryGuards = 1;
        NumEntryGuards = 3;
        NumDirectoryGuards = 3;
      };
    };
  };
}
