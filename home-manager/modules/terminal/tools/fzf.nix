# Fzf configuration with Gruvbox theming.

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
      "fg" = constants.color.fg0;
      "bg" = constants.color.bg;
      "hl" = constants.color.yellow;
      "fg+" = constants.color.fg0;
      "bg+" = constants.color.bg0;
      "hl+" = constants.color.yellow;
    };
  };
}
