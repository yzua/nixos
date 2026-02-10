# Privacy and security tools for anonymous browsing and network analysis.
# NOTE: librewolf, signal-desktop, wire-desktop, keepassxc, onionshare,
#       metadata-cleaner, bleachbit are firejail-wrapped at system level.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Network analysis
    nmap
    tcpdump

    # Network anonymity
    i2pd
    tribler

    # Privacy browsers
    mullvad-browser
    tor-browser

    # Secure Boot preparation
    sbctl
    tpm2-tools

    # Security tools
    socat # Network relay
    srm # Secure file removal
    veracrypt # Disk encryption
  ];
}
