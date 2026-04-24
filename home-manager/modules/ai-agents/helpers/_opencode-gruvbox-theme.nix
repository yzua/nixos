# Gruvbox Dark theme definition for OpenCode TUI.
# Used by files.nix to generate per-profile theme files.

{ color }:

let
  defs = {
    bg0 = color.bg;
    bg1 = color.bg_soft;
    bg2 = color.bg0;
    bg3 = color.bg1;
    bg4 = color.fg_dark;
    fg2 = color.gray_dim;
  }
  // {
    inherit (color)
      fg0
      yellow
      blue
      purple
      red
      green
      aqua
      orange
      ;
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
