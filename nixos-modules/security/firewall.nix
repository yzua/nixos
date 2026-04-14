# Network firewall and hostname leak prevention.
# Kill switch handled by Mullvad lockdown mode (nftables), not iptables.
# All rules use nftables for consistency with Mullvad and OpenSnitch.

_:

{
  networking.firewall = {
    enable = true;
    logRefusedConnections = true;
    rejectPackets = false; # Drop instead of reject for stealth
    allowedTCPPorts = [ 53317 ]; # LocalSend
    allowedUDPPorts = [ 53317 ]; # LocalSend

    extraCommands = ''
      # === Hostname Leak Prevention (iptables — kernel nf_tables handles both) ===
      iptables -A OUTPUT -p udp --dport 5355 -j DROP   # LLMNR
      iptables -A OUTPUT -p udp --dport 137:138 -j DROP # NetBIOS
      iptables -A OUTPUT -p tcp --dport 139 -j DROP     # NetBIOS
      iptables -A OUTPUT -p tcp --dport 445 -j DROP     # SMB

      # === Docker bridge forwarding ===
      iptables -A FORWARD -i docker0 -j ACCEPT
      iptables -A FORWARD -o docker0 -j ACCEPT
      iptables -A FORWARD -i br-+ -j ACCEPT
      iptables -A FORWARD -o br-+ -j ACCEPT
      iptables -A INPUT -i docker0 -j ACCEPT
      iptables -A INPUT -i br-+ -j ACCEPT
    '';

    # === nftables rules — evaluated AFTER iptables rules ===
    # These add defense-in-depth on the nftables side
    extraInputRules = ''
      # Rate-limit ICMP echo (ping flood prevention)
      ip protocol icmp limit rate 1/second burst 5 packets accept
      ip6 nexthdr icmpv6 limit rate 1/second burst 5 packets accept
    '';
  };
}
