# Privacy and security tools for anonymous browsing and network analysis.
# NOTE: librewolf, signal-desktop, wire-desktop, keepassxc, onionshare,
#       metadata-cleaner, bleachbit are firejail-wrapped at system level.
{
  pkgs,
  pkgsStable,
  ...
}:

let
  eglWrap = import ./_egl-wrap.nix { inherit pkgs; };
  inherit (eglWrap) wrapWithMesaEgl;
in
{
  home.packages = with pkgsStable; [
    # Network analysis
    nmap
    tcpdump

    # Network anonymity
    i2pd
    tribler

    # Privacy browsers — wrapped to force Mesa EGL (see wrapWithMesaEgl above)
    (wrapWithMesaEgl "mullvad-browser" mullvad-browser)
    (wrapWithMesaEgl "tor-browser" tor-browser)

    # Secure Boot preparation
    sbctl
    tpm2-tools

    # Security tools
    socat # Network relay
    srm # Secure file removal
    veracrypt # Disk encryption

    # Supply-chain and vulnerability scanning
    gitleaks # Pre-commit/pre-push secret scanning
    trivy # Vulnerability, misconfiguration, and secret scanning
    vulnix # Nix closure CVE checker
  ];
}
