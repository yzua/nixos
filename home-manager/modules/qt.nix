# Qt theming (Kvantum + Gruvbox).
{ lib, pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = lib.mkForce "fusion";
  };

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    gruvbox-kvantum
  ];

  # Keep Kvantum packages installed, but use Fusion for squarer widgets.
}
