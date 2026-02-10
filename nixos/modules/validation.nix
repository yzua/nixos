# Cross-module conflict assertions and dependency validation.
{ config, lib, ... }:

{
  assertions = [
    # === Power Management Daemon Conflicts ===
    {
      assertion = with config.services; !(tlp.enable && power-profiles-daemon.enable);
      message = "TLP and power-profiles-daemon cannot be enabled simultaneously. Choose one power management daemon.";
    }

    {
      assertion = with config.services; !(power-profiles-daemon.enable && thermald.enable);
      message = "power-profiles-daemon and thermald cannot be enabled simultaneously. They both manage thermal/power profiles.";
    }

    # === Audio Stack Conflicts ===
    {
      assertion = !(config.services.pulseaudio.enable && config.services.pipewire.enable);
      message = "PulseAudio and PipeWire cannot be enabled simultaneously. PipeWire provides a modern replacement for PulseAudio.";
    }

    # === Graphics Driver Conflicts ===
    {
      assertion = !(lib.elem "nouveau" config.boot.kernelModules && config.hardware.nvidia.enable);
      message = "NVIDIA proprietary and nouveau open-source drivers cannot coexist. Remove nouveau from boot.kernelModules.";
    }

    # === Gaming System Dependencies ===
    {
      assertion = !config.mySystem.gaming.enable || config.hardware.graphics.enable;
      message = "Gaming requires hardware.graphics.enable = true. Graphics drivers must be configured.";
    }

    {
      assertion = !config.mySystem.gaming.enable || config.services.pipewire.pulse.enable;
      message = "Gaming requires PipeWire with PulseAudio compatibility layer (services.pipewire.pulse.enable = true).";
    }

    # === VPN/Network Dependencies ===
    {
      assertion = !config.mySystem.mullvadVpn.enable || config.networking.networkmanager.enable;
      message = "Mullvad VPN requires NetworkManager (networking.networkmanager.enable = true).";
    }

    # === Security Configuration Validation ===
    {
      assertion = with config.networking.firewall; enable;
      message = "Firewall must be enabled (networking.firewall.enable = true) for system security.";
    }

    {
      assertion =
        !config.mySystem.sandboxing.enable
        || config.boot.kernel.sysctl."kernel.unprivileged_userns_clone" == 1;
      message = "Sandboxing requires unprivileged user namespaces (boot.kernel.sysctl.'kernel.unprivileged_userns_clone' = 1).";
    }

    # === Network Service Security ===
    {
      assertion = !config.services.avahi.enable || config.services.avahi.allowInterfaces != [ ];
      message = "Avahi must have explicit allowInterfaces list for security. Don't expose mDNS on all interfaces.";
    }

    {
      assertion = !config.mySystem.dnscryptProxy.enable || !config.services.resolved.enable;
      message = "DNSCrypt-Proxy and systemd-resolved cannot both manage DNS. Disable resolved when using DNSCrypt.";
    }

    # === Display Manager Conflicts ===
    {
      assertion = !(config.services.displayManager.gdm.enable && config.services.greetd.enable);
      message = "GDM and greetd cannot be enabled simultaneously. Choose one display manager.";
    }

    # === Hardening Validation ===
    {
      assertion = config.security.apparmor.enable;
      message = "AppArmor must be enabled (security.apparmor.enable = true) for mandatory access control.";
    }
  ];

  warnings = lib.optional config.services.prometheus.exporters.node.enable "prometheus.exporters.node was removed due to service failures. Use Netdata (mySystem.netdata.enable) instead.";
}
