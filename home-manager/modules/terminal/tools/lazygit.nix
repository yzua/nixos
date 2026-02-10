# Lazygit (Git TUI) configuration.

{ constants, ... }:

{
  programs.lazygit = {
    enable = true;

    settings = {
      gui.showIcons = true;

      gui.theme = {
        lightTheme = false;
        activeBorderColor = [
          constants.color.green
          "bold"
        ];
        inactiveBorderColor = [ constants.color.gray ];
        selectedLineBgColor = [ constants.color.blue_dim ];
      };
    };
  };
}
