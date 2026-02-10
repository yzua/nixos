# Qt theming (Kvantum + Gruvbox).
{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    gruvbox-kvantum
  ];

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=gruvbox-kvantum
  '';
}
