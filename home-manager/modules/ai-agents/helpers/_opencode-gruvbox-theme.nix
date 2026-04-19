# Gruvbox Dark theme definition for OpenCode TUI.
# Used by files.nix to generate per-profile theme files.

let
  defs = {
    bg0 = "#282828";
    bg1 = "#32302f";
    bg2 = "#3c3836";
    bg3 = "#504945";
    bg4 = "#665c54";
    fg0 = "#ebdbb2";
    fg2 = "#a89984";
    yellow = "#fabd2f";
    blue = "#83a598";
    purple = "#d3869b";
    red = "#fb4934";
    green = "#b8bb26";
    aqua = "#8ec07c";
    orange = "#fe8019";
  };
in
{
  "$schema" = "https://opencode.ai/theme.json";
  inherit defs;
  theme = {
    primary.dark = "yellow";
    primary.light = "yellow";
    secondary.dark = "blue";
    secondary.light = "blue";
    accent.dark = "purple";
    accent.light = "purple";
    error.dark = "red";
    error.light = "red";
    warning.dark = "orange";
    warning.light = "orange";
    success.dark = "green";
    success.light = "green";
    info.dark = "aqua";
    info.light = "aqua";
    text.dark = "fg0";
    text.light = "fg0";
    textMuted.dark = "fg2";
    textMuted.light = "fg2";
    background.dark = "bg0";
    background.light = "bg0";
    backgroundPanel.dark = "bg1";
    backgroundPanel.light = "bg1";
    backgroundElement.dark = "bg2";
    backgroundElement.light = "bg2";
    border.dark = "bg3";
    border.light = "bg3";
    borderActive.dark = "bg4";
    borderActive.light = "bg4";
    borderSubtle.dark = "bg2";
    borderSubtle.light = "bg2";
  };
}
