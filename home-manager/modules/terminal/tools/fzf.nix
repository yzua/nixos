# Fzf configuration with full Gruvbox dark soft theming.

{ constants, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    colors = {
      # Text colors
      "fg" = constants.color.fg0;
      "bg" = constants.color.bg_soft;
      "hl" = constants.color.yellow;
      # Selected item
      "fg+" = constants.color.fg0;
      "bg+" = constants.color.bg0;
      "hl+" = constants.color.yellow;
      # UI elements
      "info" = constants.color.aqua;
      "prompt" = constants.color.blue;
      "pointer" = constants.color.orange;
      "marker" = constants.color.green;
      "spinner" = constants.color.purple;
      "header" = constants.color.gray;
      # Border and gutter
      "border" = constants.color.bg1;
      "gutter" = constants.color.bg;
    };
  };
}
