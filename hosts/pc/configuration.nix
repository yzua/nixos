# Desktop workstation: gaming, NVIDIA GPU, ethernet.
{ stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  networking.hostName = hostname;
  system = { inherit stateVersion; };

  # LUKS unlock for swap partition (from installer's configuration.nix)
  boot.initrd.luks.devices."luks-4e98b5c2-4022-41a6-8e97-dddf0fe5c408".device =
    "/dev/disk/by-uuid/4e98b5c2-4022-41a6-8e97-dddf0fe5c408";

  mySystem.hostProfile = "desktop";
  mySystem.netdata.enable = true;

  services.avahi.allowInterfaces = [ "eno1" ];
}
