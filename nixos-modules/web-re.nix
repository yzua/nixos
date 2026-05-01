# Web reverse engineering and security assessment tools.
# Static analysis of JS, dynamic API discovery, vulnerability scanning, CVE detection.

{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.mySystem.webRe = {
    enable = lib.mkEnableOption "web reverse engineering and security tools";
  };

  config = lib.mkIf config.mySystem.webRe.enable {
    environment.systemPackages = with pkgs; [
      # === Vulnerability scanning ===
      nuclei # Fast vuln scanner with community CVE templates (ProjectDiscovery)
      nikto # Web server vulnerability scanner
      sqlmap # SQL injection detection and exploitation
      subfinder # Passive subdomain discovery
      amass # In-depth DNS enumeration and network mapping

      # === Web reconnaissance ===
      httpx # Fast HTTP prober (live hosts, titles, tech stack, TLS)
      katana # Web crawler/spider with JS parsing and endpoint extraction
      ffuf # Fast web fuzzer (directories, vhosts, parameters)
      arjun # HTTP parameter discovery
      whatweb # Website technology fingerprinter

      # === Web app testing ===
      dalfox # XSS scanner with WAF bypass payloads
      zap # OWASP ZAP web proxy and vulnerability scanner

      # === Crypto / cert analysis ===
      # openssl — already in home-manager/packages/networking.nix
    ];

    environment.sessionVariables = {
      # nuclei templates directory (default location after first `nuclei -update-templates`)
      NUCLEI_TEMPLATES_PATH = "$HOME/.local/share/nuclei-templates";
    };

    # TPROXY kernel modules for mitmproxy transparent proxy mode
    boot.kernelModules = [
      "xt_TPROXY"
      "nf_tproxy_ipv4"
      "nf_tproxy_ipv6"
      "nf_conntrack"
    ];
  };
}
