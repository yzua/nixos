# Stylix theming engine (Gruvbox dark, flat style).
{
  constants,
  inputs,
  pkgsStable,
  ...
}:

{
  imports = [ inputs.stylix.homeModules.stylix ];

  home.packages = with pkgsStable; [
    dejavu_fonts
    jetbrains-mono
    noto-fonts
    noto-fonts-lgc-plus
    texlivePackages.hebrew-fonts
    noto-fonts-color-emoji
    font-awesome
    powerline-fonts
    powerline-symbols
    nerd-fonts.jetbrains-mono
  ];

  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgsStable.base16-schemes}/share/themes/${constants.theme}.yaml";

    enableReleaseChecks = false;

    # Noctalia Shell handles desktop theming; only GTK/Qt base themes enabled
    autoEnable = false;
    targets = {
      ghostty.enable = true;
      gtk.enable = true;
      qt.enable = true;
      neovim.enable = true;
      zellij.enable = true;
      noctalia-shell.enable = false;
    };

    cursor = {
      name = "Bibata-Modern-Classic";
      size = 24;
      package = pkgsStable.bibata-cursors;
    };

    fonts = {
      emoji = {
        name = "Noto Color Emoji";
        package = pkgsStable.noto-fonts-color-emoji;
      };

      monospace = {
        name = constants.font.mono;
        package = pkgsStable.jetbrains-mono;
      };

      sansSerif = {
        name = "Noto Sans";
        package = pkgsStable.noto-fonts;
      };

      serif = {
        name = "Noto Serif";
        package = pkgsStable.noto-fonts;
      };

      sizes =
        let
          inherit (constants.font) size;
        in
        {
          terminal = size;
          applications = 11;
        };
    };

    icons = {
      enable = true;
      package = pkgsStable.gruvbox-plus-icons;
      dark = "Gruvbox-Plus-Dark";
      light = "Gruvbox-Plus-Light";
    };

  };
}
