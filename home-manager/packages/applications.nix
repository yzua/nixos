# Desktop applications and theming packages.
{
  pkgs,
  pkgsStable,
  ...
}:

{
  home.packages = [
    (pkgs.bottles.override { removeWarningPopup = true; })
    pkgs.pear-desktop
    pkgs.obsidian
    pkgsStable.keepassxc
    pkgsStable.librewolf
    pkgsStable.vscode-fhs

    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
