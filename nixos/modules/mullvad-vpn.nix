# Mullvad VPN with hardened tunnel settings.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.mullvadVpn = {
    enable = lib.mkEnableOption "Mullvad VPN service";
  };

  config = lib.mkIf config.mySystem.mullvadVpn.enable {
    # DNS handled by DNSCrypt-Proxy, not Mullvad's resolver.
    # Resolved conflict validated in validation.nix.

    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn; # Includes GUI
    };

    # Declarative settings applied after daemon starts
    systemd.services.mullvad-settings = {
      description = "Apply declarative Mullvad VPN settings";
      after = [ "mullvad-daemon.service" ];
      requires = [ "mullvad-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mullvad=${pkgs.mullvad}/bin/mullvad

        # Wait for mullvad daemon RPC socket to be ready
        for i in $(seq 1 30); do
          $mullvad status >/dev/null 2>&1 && break
          sleep 1
        done

        # === DNS ===
        # Route through local dnscrypt-proxy (127.0.0.1:53) instead of Mullvad's DNS.
        # Prevents DNS conflicts and keeps encrypted DNS under our control.
        $mullvad dns set custom 127.0.0.1

        # === Kill Switch ===
        # Block ALL traffic when VPN is disconnected. No leaks.
        $mullvad lockdown-mode set on

        # === Auto-connect ===
        # Reconnect VPN automatically on boot/network change.
        $mullvad auto-connect set on

        # === Relay Selection ===
        # Random exit server, no multihop.
        # Multihop (US entry → random exit) disabled: from Jordan, routing through
        # a US entry server adds latency and often fails with obfuscation, causing
        # 10-15min connection loops at boot. Re-enable on unrestricted networks.
        $mullvad relay set multihop off
        $mullvad relay set location any

        # === Tunnel Hardening ===
        # Quantum-resistant key exchange (post-quantum crypto on top of WireGuard)
        $mullvad tunnel set quantum-resistant on
        # DAITA disabled: from Jordan, DAITA + obfuscation causes connection failures.
        # Mullvad auto-disables it after repeated failures anyway. Re-enable on
        # unrestricted networks where direct WireGuard works.
        $mullvad tunnel set daita off
        # Disable IPv6 in tunnel (matches networking.enableIPv6 = false)
        $mullvad tunnel set ipv6 off
        # Rotate WireGuard keys every 24 hours for forward secrecy
        $mullvad tunnel set rotation-interval 24

        # === Obfuscation ===
        # Auto-detect censorship and apply obfuscation when needed.
        $mullvad obfuscation set mode auto

        # === Local Network ===
        # Block LAN access while connected (no local device leaks)
        $mullvad lan set block
      '';
    };
  };
}
