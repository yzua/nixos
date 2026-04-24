# libvirt/QEMU virtual machine management.

{
  config,
  lib,
  pkgsStable,
  user,
  ...
}:

{
  options.mySystem.libvirt = {
    enable = lib.mkEnableOption "libvirt/QEMU virtual machine management";
  };

  config = lib.mkIf config.mySystem.libvirt.enable {
    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
      onBoot = "ignore";

      qemu = {
        package = pkgsStable.qemu_kvm;
        swtpm.enable = true;
      };
    };

    users.users."${user}".extraGroups = [
      "libvirtd"
    ];

    systemd = {
      # Socket-activate libvirtd — daemon starts only on first virsh/virt-manager use
      services.libvirtd.wantedBy = lib.mkForce [ ];
      sockets.libvirtd.wantedBy = [ "sockets.target" ];

      # Disable libvirt-guests entirely — onBoot = "ignore" makes it pointless,
      # and its default shutdown handling can block poweroff for minutes.
      services.libvirt-guests.enable = false;
    };

    environment.systemPackages = [
      pkgsStable.virt-manager
    ];
  };
}
