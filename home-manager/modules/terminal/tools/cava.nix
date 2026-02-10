# Cava audio visualizer configuration.

{ constants, ... }:

{
  programs.cava = {
    enable = true;

    settings = {
      general = {
        framerate = 60;
        sensitivity = 80;
        autosens = 1;
      };

      # Gruvbox palette (Stylix doesn't support cava)
      color = {
        gradient = 1;
        gradient_color_1 = "'${constants.color.fg0}'";
        gradient_color_2 = "'${constants.color.orange_dim}'";
        gradient_color_3 = "'${constants.color.yellow}'";
        gradient_color_4 = "'${constants.color.aqua}'";
        gradient_color_5 = "'${constants.color.blue}'";
        gradient_color_6 = "'${constants.color.purple}'";
        gradient_color_7 = "'${constants.color.red}'";
        gradient_color_8 = "'${constants.color.orange}'";
      };
    };
  };
}
