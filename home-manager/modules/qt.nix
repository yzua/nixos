# Qt theming (Kvantum + Gruvbox).

{
  constants,
  lib,
  pkgs,
  ...
}:

let
  qt5ctSettings = {
    Appearance = {
      custom_palette = false;
      icon_theme = "Gruvbox-Plus-Dark";
      standard_dialogs = "default";
      style = "kvantum";
    };
    Fonts = {
      fixed = "\"${constants.font.mono},${toString constants.font.sizeApplications}\"";
      general = "\"Noto Sans,${toString constants.font.sizeApplications}\"";
    };
  };
  qt6ctSettings = qt5ctSettings;
in
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = lib.mkForce "kvantum";
    inherit qt5ctSettings qt6ctSettings;
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
    theme=Gruvbox-Dark-Brown
  '';

  # Force Qt apps to a deterministic dark Gruvbox Kvantum theme.
}
