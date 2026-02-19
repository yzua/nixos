# Syncthing decentralized file sync.
{ pkgs, ... }:

{
  services.syncthing = {
    enable = true;

    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };
}
