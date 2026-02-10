# Desktop applications and theming packages.
{
  pkgs,
  pkgsStable,
  ...
}:

{
  home.packages = [
    (pkgs.bottles.override { removeWarningPopup = true; })
    pkgs.spotube
    pkgsStable.librewolf

    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
