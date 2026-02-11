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
    # LibreWolf: force Mesa EGL to avoid NVIDIA LLVM OOM crash during shader compilation.
    # NVIDIA's EGL (10_nvidia.json) takes priority by default and its LLVM JIT OOMs on startup.
    (pkgs.symlinkJoin {
      name = "librewolf";
      paths = [ pkgsStable.librewolf ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/librewolf \
          --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      '';
    })
    pkgsStable.vscode-fhs

    # GTK theming
    pkgsStable.gnome-themes-extra
    pkgsStable.gruvbox-gtk-theme
  ];
}
