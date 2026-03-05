# Desktop applications and theming packages.
{
  pkgs,
  pkgsStable,
  ...
}:
{
  home.packages = [
    (pkgs.bottles.override { removeWarningPopup = true; })
    pkgs.element-desktop
    pkgsStable.imv
    pkgs.localsend
    pkgsStable.libreoffice-qt6-fresh
    pkgsStable.sqlitebrowser
    pkgsStable.keepassxc
    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
