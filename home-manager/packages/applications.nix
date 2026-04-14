# Desktop applications and theming packages.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (bottles.override { removeWarningPopup = true; })
    code-cursor-fhs
    element-desktop
    google-chrome
    imv
    kiro-fhs
    localsend
    libreoffice-qt6-fresh
    sqlitebrowser
    keepassxc
    antigravity-fhs

    # Messaging
    signal-desktop
    telegram-desktop

    # VPN GUIs
    protonvpn-gui

    # Torrents
    qbittorrent

    # GTK theming
    gnome-themes-extra
    gruvbox-gtk-theme
  ];
}
