# Qt theming (Kvantum + Gruvbox).
{
  constants,
  lib,
  pkgs,
  ...
}:

{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = lib.mkForce "fusion";
    qt5ctSettings = {
      Appearance = {
        custom_palette = true;
        icon_theme = "Gruvbox-Plus-Dark";
        standard_dialogs = "default";
        style = "fusion";
      };
      Fonts = {
        fixed = "\"${constants.font.mono},11\"";
        general = "\"Noto Sans,11\"";
      };
    };
    qt6ctSettings = {
      Appearance = {
        custom_palette = true;
        icon_theme = "Gruvbox-Plus-Dark";
        standard_dialogs = "default";
        style = "fusion";
      };
      Fonts = {
        fixed = "\"${constants.font.mono},11\"";
        general = "\"Noto Sans,11\"";
      };
    };
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
