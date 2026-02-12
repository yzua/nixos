# Zathura PDF viewer configuration.

{ constants, ... }:

{
  programs.zathura = {
    enable = true;

    mappings = {
      D = "toggle_page_mode";
      d = "scroll half_down";
      u = "scroll half_up";
    };

    options = {
      font = "${constants.font.mono} Bold ${toString constants.font.size}";
    };
  };
}
