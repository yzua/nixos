# Networking tools for analysis, monitoring, and security testing.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Core networking (networkmanagerapplet managed by services.network-manager-applet)
    openssh
    openssl
    openssl.dev

    # Diagnostics
    iperf3
    mtr
    trippy

    # DNS utilities
    dnsutils
    dog
    whois

    # HTTP clients
    curl
    wget

    # Network debugging
    netcat

    # Network monitoring
    bandwhich # Per-process/host bandwidth monitor
    iftop
    nethogs
    nload
    termshark # TUI Wireshark (pcap analysis in terminal)

    # Network scanning
    masscan
    zmap

    # Security testing
    hydra

    # VPN tools
    openvpn
    wireguard-tools
  ];
}
