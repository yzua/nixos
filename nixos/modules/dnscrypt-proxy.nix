# Encrypted DNS via DNSCrypt-Proxy (DoH/DoT with DNSSEC).
{ config, lib, ... }:

{
  options.mySystem.dnscryptProxy = {
    enable = lib.mkEnableOption "DNSCrypt-Proxy for encrypted DNS and DNS leak prevention";
  };

  config = lib.mkIf config.mySystem.dnscryptProxy.enable {
    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        listen_addresses = [ "127.0.0.1:53" ];

        # Diversified resolvers — prevents single-provider compromise
        server_names = [
          "quad9-dnscrypt-ip4-nofilter-pri" # Swiss jurisdiction, no filtering
          "mullvad-doh" # Swedish jurisdiction, no-log
          "dnscrypt.ca-1-ipv4" # Canadian, no-log
        ];

        # Only used to resolve DoH server addresses, not regular queries.
        bootstrap_resolvers = [
          "1.1.1.1:53"
          "9.9.9.9:53"
        ];

        # PRIVACY: Fail rather than leak if encrypted DNS is unavailable
        fallback_resolvers = [ ];
        ignore_system_dns = true;

        cache = true;
        cache_size = 4096;
        cache_min_ttl = 600;
        cache_max_ttl = 86400;

        require_dnssec = true;
        require_nolog = true;
        require_nofilter = true;

        blocked_names = {
          blocked_names_file = "/var/lib/dnscrypt-proxy/blocked-names.txt";
        };

        log_level = 0; # Critical errors only
        block_ipv6 = true;
      };
    };

    systemd.tmpfiles.rules = [
      "f /var/lib/dnscrypt-proxy/blocked-names.txt 0644 root root - # DNSCrypt blocklist"
    ];
  };
}
