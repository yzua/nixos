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
      "iptable_filter"
      "iptable_mangle"
      "iptable_raw"
      "iptable_nat"
      "xt_MASQUERADE"
      "xt_comment"
      "xt_connmark"
      "xt_mark"
      "nf_nat"
      "xt_addrtype"
      "overlay"
    ];

    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = true;
      "net.bridge.bridge-nf-call-ip6tables" = true;
      "net.ipv4.ip_forward" = true;
    };

    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = true;
        rootless = {
          enable = false;
          setSocketVariable = true;
        };
        daemon.settings = {
          dns = [ "172.17.0.1" ];
          ipv6 = false;
          iptables = true;
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

    networking.firewall.trustedInterfaces = [ "docker0" ];

    # Let Docker manage its own FORWARD/NAT chains.
    # NixOS firewall blocks forwarded traffic by default — this breaks Docker bridges.
    networking.firewall.filterForward = false;

    environment.systemPackages = with pkgsStable; [
      virt-manager
      nvidia-container-toolkit
    ];
  };
}
