# Desktop workstation: gaming, NVIDIA GPU, ethernet.
{ stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  # Host identity managed by nixos/modules/host-info.nix
  mySystem = {
    hostInfo.enable = true;
    hostProfile = "desktop";
    netdata.enable = true;
  };

  # LUKS unlock for swap partition (from installer's configuration.nix)
  boot.initrd.luks.devices."luks-4e98b5c2-4022-41a6-8e97-dddf0fe5c408".device =
    "/dev/disk/by-uuid/4e98b5c2-4022-41a6-8e97-dddf0fe5c408";

  services.avahi.allowInterfaces = [ "eno1" ];
}
