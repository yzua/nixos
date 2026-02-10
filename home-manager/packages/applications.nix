# Desktop applications and theming packages.
{
  pkgs,
  pkgsStable,
  ...
}:

{
  home.packages = [
    (pkgs.bottles.override { removeWarningPopup = true; })
    pkgs.youtube-music
    pkgs.obsidian
    pkgsStable.keepassxc
    pkgsStable.librewolf

    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
