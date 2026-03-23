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

    # Mullvad's packaged unit waits for network-online, which adds ~14s of
    # boot delay via NetworkManager-wait-online. Starting after NetworkManager
    # is sufficient; the daemon can reconnect as soon as the link is usable.
    systemd.services.mullvad-daemon = {
      wants = lib.mkForce [ "network.target" ];
      after = lib.mkForce [
        "network.target"
        "NetworkManager.service"
      ];
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
        # Do not set Mullvad-side custom DNS. The host already resolves through
        # local dnscrypt-proxy via resolv.conf/NetworkManager. Forcing Mullvad's
        # tunnel DNS to 127.0.0.1 adds unnecessary complexity and can slow tunnel
        # establishment.
        $mullvad dns set default

        # === Kill Switch ===
        # Block ALL traffic when VPN is disconnected. No leaks.
        $mullvad lockdown-mode set on

        # === Auto-connect ===
        # Reconnect VPN automatically on boot/network change.
        $mullvad auto-connect set on

        # === Relay Selection ===
        # Prefer the currently reliable nearby region instead of `location any`.
        # Random far-away relays caused repeated WireGuard timeout/obfuscation
        # loops during boot before eventually landing on Israel anyway.
        $mullvad relay set multihop off
        $mullvad relay set location il

        # === Tunnel Hardening ===
        # Quantum-resistant key exchange (post-quantum crypto on top of WireGuard)
        $mullvad tunnel set quantum-resistant on
        # DAITA disabled: from Jordan, DAITA + obfuscation causes connection failures.
        # Mullvad auto-disables it after repeated failures anyway. Re-enable on
        # unrestricted networks where direct WireGuard works.
        $mullvad tunnel set daita off
        # Disable IPv6 inside Mullvad tunnel (Yggdrasil can still use kernel IPv6 stack)
        $mullvad tunnel set ipv6 off
        # Rotate WireGuard keys every 24 hours for forward secrecy
        $mullvad tunnel set rotation-interval 24

        # === Obfuscation ===
        # Auto-detect censorship and apply obfuscation when needed.
        $mullvad obfuscation set mode auto

        # === Local Network ===
        # SECURITY: Only allow LAN access when services need it (KDE Connect, LocalSend).
        # On public/hostile networks, LAN access is an attack surface.
        ${
          if (config.mySystem.kdeconnect.enable || config.mySystem.flatpak.enable) then
            ''
              $mullvad lan set allow
            ''
          else
            ''
              $mullvad lan set block
            ''
        }
      '';
    };
  };
}
