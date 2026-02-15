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
    pkgsStable.keepassxc
    # LibreWolf: HM package provides .desktop file + icons for app launcher.
    # HM binary shadows the firejail-wrapped system binary, so wrap with Mesa EGL here too.
    (pkgs.symlinkJoin {
      name = "librewolf";
      paths = [ pkgsStable.librewolf ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/librewolf \
          --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
    })
    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
