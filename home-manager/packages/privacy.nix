# Privacy and security tools for anonymous browsing and network analysis.
# NOTE: librewolf, signal-desktop, wire-desktop, keepassxc, onionshare,
#       metadata-cleaner, bleachbit are firejail-wrapped at system level.
{
  pkgs,
  pkgsStable,
  ...
}:

let
  # Force Mesa EGL to avoid NVIDIA LLVM OOM crash during shader compilation.
  # NVIDIA's EGL (10_nvidia.json) takes priority by default and its LLVM JIT
  # OOMs on Firefox-family browsers. Also set system-wide in nvidia.nix, but
  # wrapProgram ensures it works even before relogin or in non-login shells.
  wrapWithMesaEgl =
    name: pkg:
    pkgs.symlinkJoin {
      inherit name;
      paths = [ pkg ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${name} \
          --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
    };
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
