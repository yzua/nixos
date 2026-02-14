# Application configuration modules.
{
  imports = [
    ./keepassxc.nix # KeePassXC desktop entry (binary is firejail-wrapped)
    ./obs.nix # OBS Studio with CUDA and plugins
    ./syncthing.nix # Syncthing local file sync
    ./nixcord.nix # Discord (Vesktop + Vencord)
    ./activitywatch.nix # ActivityWatch app usage tracking
    ./opensnitch-ui.nix # OpenSnitch application firewall GUI
    ./nautilus.nix # Nautilus (GNOME Files) dconf preferences
    ./vscode # VS Code editor with extensions and settings
    ./obsidian.nix # Obsidian Markdown notes app defaults
    ./pear-desktop.nix # Pear Desktop theme + plugin baseline
  ];
}
