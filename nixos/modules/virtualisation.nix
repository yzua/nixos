# Docker and libvirt/QEMU virtualisation.
{
  config,
  lib,
  pkgsStable,
  user,
  ...
}:

{
  options.mySystem.virtualisation = {
    enable = lib.mkEnableOption "Docker, libvirt/QEMU virtualisation support";
  };

  config = lib.mkIf config.mySystem.virtualisation.enable {
    boot.kernelModules = [ "kvm" ]; # intel/amd modules auto-detected

    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = false;
        daemon.settings = {
          # Route container DNS through DNSCrypt-Proxy on host.
          # NOTE: flaresolverr container tries to resolve "redis" (no redis running) —
          # fix at container level, not here.
          dns = [ "127.0.0.1" ];
          ipv6 = false;
          iptables = true;
        };
        rootless.enable = false; # System Docker handles all containers
      };

      libvirtd = {
        enable = true;
        onShutdown = "shutdown";
        onBoot = "ignore";

        qemu = {
          package = pkgsStable.qemu_kvm;
          swtpm.enable = true;
        };
      };
    };

    users.users."${user}".extraGroups = [
      "docker"
      "libvirtd"
      "kvm"
    ];

    systemd = {
      # Socket-activate libvirtd — daemon starts only on first virsh/virt-manager use
      services.libvirtd.wantedBy = lib.mkForce [ ];
      sockets.libvirtd.wantedBy = [ "sockets.target" ];

      # Disable libvirt-guests entirely — onBoot = "ignore" makes it pointless,
      # and missing /var/lib/libvirt/libvirt-guests state file causes boot hangs.
      services.libvirt-guests.wantedBy = lib.mkForce [ ];
    };

    # Only enable GPU containers on desktop (Optimus laptops can't reliably passthrough)
    hardware.nvidia-container-toolkit.enable =
      config.mySystem.nvidia.enable && (config.mySystem.hostProfile == "desktop");

    environment.systemPackages = with pkgsStable; [
      virt-manager
      nvidia-container-toolkit
    ];
  };
}
