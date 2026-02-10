# Network firewall and hostname leak prevention.
# Kill switch handled by Mullvad lockdown mode (nftables), not iptables.
_:

{
  networking.firewall = {
    enable = true;
    logRefusedConnections = true;
    rejectPackets = false; # Drop instead of reject for stealth
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    allowedTCPPortRanges = [ ];
    allowedUDPPortRanges = [ ];

    extraCommands = ''
      # === Hostname Leak Prevention ===
      iptables -A OUTPUT -p udp --dport 5355 -j DROP   # LLMNR
      iptables -A OUTPUT -p udp --dport 137:138 -j DROP # NetBIOS
      iptables -A OUTPUT -p tcp --dport 139 -j DROP     # NetBIOS
      iptables -A OUTPUT -p tcp --dport 445 -j DROP     # SMB
    '';
  };
}
