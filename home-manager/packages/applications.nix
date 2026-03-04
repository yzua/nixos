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
    pkgs.localsend
    pkgs.pear-desktop
    pkgsStable.keepassxc
    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
