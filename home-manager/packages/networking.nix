# Networking tools for analysis, monitoring, and security testing.
# NOTE: openssh managed by services.openssh, bandwhich by programs.bandwhich
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core networking (networkmanagerapplet managed by services.network-manager-applet)
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

    # Network monitoring (bandwhich managed by programs.bandwhich)
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
    proton-vpn-cli
    wireguard-tools
    wgnord
  ];
}
