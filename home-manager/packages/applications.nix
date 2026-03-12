# Desktop applications and theming packages.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (bottles.override { removeWarningPopup = true; })
    element-desktop
    imv
    localsend
    libreoffice-qt6-fresh
    sqlitebrowser
    keepassxc

    # Messaging
    signal-desktop
    telegram-desktop

    # Torrents
    qbittorrent

    # GTK theming
    gnome-themes-extra
    gruvbox-gtk-theme
  ];
}
