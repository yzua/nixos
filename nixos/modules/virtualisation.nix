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
    boot.kernelModules = [
      "kvm" # intel/amd modules auto-detected
      "bridge"
      "br_netfilter"
      "ip_tables"
      "iptable_nat"
      "nf_nat"
      "xt_addrtype"
    ];

    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = false;
        rootless = {
          enable = true;
          setSocketVariable = true; # Set DOCKER_HOST for rootless socket
        };
        daemon.settings = {
          # Route container DNS through DNSCrypt-Proxy on host.
          # NOTE: flaresolverr container tries to resolve "redis" (no redis running) —
          # fix at container level, not here.
          dns = [ "127.0.0.1" ];
          ipv6 = false;
          iptables = true;
          # SECURITY: Limit container capabilities
          "no-new-privileges" = true;
          # SECURITY: Default seccomp profile (blocks dangerous syscalls)
          seccomp-profile = "";
        };
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
      # and its default shutdown handling can block poweroff for minutes.
      services.libvirt-guests.enable = false;
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
