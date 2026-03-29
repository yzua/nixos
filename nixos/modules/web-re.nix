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
      nmap # Network/port scanner, service fingerprinting
      subfinder # Passive subdomain discovery

      # === Web reconnaissance ===
      whatweb # Website technology fingerprinter
      jq # JSON processing for API response analysis

      # === JS / web analysis ===
      nodejs # Node.js runtime (for js-beautify, source-map-explorer, etc.)
      python3 # Python runtime (for scripts, requests, beautifulsoup4)

      # === Crypto / cert analysis ===
      # openssl — already in home-manager/packages/networking.nix
    ];

    environment.sessionVariables = {
      # nuclei templates directory (default location after first `nuclei -update-templates`)
      NUCLEI_TEMPLATES_PATH = "$HOME/.local/share/nuclei-templates";
    };
  };
}
