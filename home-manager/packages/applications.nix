# Desktop applications and theming packages.
{
  pkgs,
  pkgsStable,
  ...
}:

let
  eglWrap = import ./_egl-wrap.nix { inherit pkgs; };
  inherit (eglWrap) wrapWithMesaEgl;
in
{
  home.packages = [
    (pkgs.bottles.override { removeWarningPopup = true; })
    pkgs.pear-desktop
    pkgsStable.keepassxc
    # LibreWolf: HM package provides .desktop file + icons for app launcher.
    # HM binary shadows the firejail-wrapped system binary, so wrap with Mesa EGL here too.
    (wrapWithMesaEgl "librewolf" pkgsStable.librewolf)
    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
