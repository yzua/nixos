# Syncthing decentralized file sync.
_:

{
  services.syncthing = {
    enable = true;

    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };
}
