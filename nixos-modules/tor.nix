# Tor SOCKS proxy and onion routing.

{
  config,
  constants,
  lib,
  ...
}:

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

      client = {
        enable = true;
        # Override the NixOS default (IsolateDestAddr = true).
        # relayrad already isolates per-request via unique SOCKS5 auth credentials,
        # which Tor uses as circuit isolation keys (IsolateSOCKSAuth).  IsolateDestAddr
        # forces a separate circuit per destination on top of that, dramatically
        # increasing circuit pressure and causing timeouts when guards are overloaded.
        socksListenAddress = {
          addr = constants.localhost;
          port = constants.ports.tor-socks;
        };
      };

      settings = {
        DNSPort = [
          {
            addr = constants.localhost;
            port = constants.ports.tor-dns;
          }
        ];
        AutomapHostsOnResolve = true;
        AutomapHostsSuffixes = [
          ".onion"
          ".exit"
          ".noconnect"
        ];

        # Prefer exits in privacy-friendly jurisdictions, but allow fallback
        # to any country (StrictNodes = 0) when preferred exits are overloaded.
        # Widened from the original {de,nl,ch,fi,is,ro} for better availability.
        ExitNodes = "{de},{nl},{ch},{fi},{is},{ro},{se},{no},{dk},{fr},{ca},{jp}";

        IPv6Exit = false;
        StrictNodes = 0;

        UseEntryGuards = 1;
        NumEntryGuards = 3;
        NumDirectoryGuards = 3;

        # Give circuits more time to build when the network is congested.
        CircuitBuildTimeout = 90;

        # Start building circuits immediately on daemon startup instead of
        # waiting for the first SOCKS connection.
        DormantCanceledByStartup = true;
      };
    };
  };
}
