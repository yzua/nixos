# Encrypted DNS via DNSCrypt-Proxy (DoH/DoT with DNSSEC) with ad/tracker blocking.

{ config, lib, ... }:

{
  options.mySystem.dnscryptProxy = {
    enable = lib.mkEnableOption "DNSCrypt-Proxy for encrypted DNS and DNS leak prevention";
  };

  config = lib.mkIf config.mySystem.dnscryptProxy.enable {
    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        listen_addresses = [
          "127.0.0.1:53"
          "172.17.0.1:53"
        ];

        # Diversified resolvers — prevents single-provider compromise
        server_names = [
          "quad9-dnscrypt-ip4-nofilter-pri" # Swiss jurisdiction, no filtering
          "mullvad-doh" # Swedish jurisdiction, no-log
          "dnscrypt.ca-1-ipv4" # Canadian, no-log
        ];

        # Only used to resolve DoH server addresses, not regular queries.
        # Use non-Cloudflare resolvers to avoid jurisdiction leakage.
        bootstrap_resolvers = [
          "9.9.9.9:53" # Quad9 (Swiss jurisdiction)
          "185.228.168.168:53" # CleanBrowsing (privacy-focused)
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

        log_level = 0; # Critical errors only
        block_ipv6 = true;

        # # === Ad/Tracker/Malware Blocking ===
        # # System-wide DNS blocking — catches ALL apps, not just browser.
        # # Uses AdGuard blocklist sources via dnscrypt-proxy's built-in cloaking.
        # blocked_names = {
        #   blocked_names_file = "/etc/dnscrypt-proxy/blocked-ips.txt";
        # };

        # sources = {
        #   adguard = {
        #     urls = [
        #       "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
        #       "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt"
        #     ];
        #     cache_file = "adguard-cache.txt";
        #     minisign_key = "RWQf5jNPnpOIzIzR5oEjRFYmP5MjxYEKHm9Y6qfhFyNuVdMU4fRJkBXs";
        #     refresh_delay = 72; # hours
        #     prefix = "adguard";
        #   };
        # };
      };
    };
  };
}
