# Application configuration modules.
{
  imports = [
    ./keepassxc.nix # KeePassXC desktop entry (binary is firejail-wrapped)
    ./obs.nix # OBS Studio with CUDA and plugins
    ./syncthing.nix # Syncthing local file sync
  ];
}
