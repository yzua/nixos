# Shared constants used across NixOS and Home Manager configurations.
# Single source of truth for terminal, editor, font, theme, and keyboard settings.
#
# Usage (in NixOS modules):
#   { constants, ... }:
#   { TERMINAL = constants.terminal; }
#
# Usage (in Home Manager modules):
#   { constants, ... }:
#   { config.programs.ghostty.settings.font-family = constants.font.mono; }

{
  # User Identity (Git, GitHub, Contact)
  user = {
    handle = "yz";
    name = "yz";
    email = "git.remarry972@simplelogin.com";
    githubEmail = "260740417+yzua@users.noreply.github.com";
    signingKey = "0x9C3EC618CFE2EB3D";
  };

  # Terminal emulator
  terminal = "ghostty";
  terminalAppId = "com.mitchellh.ghostty"; # Wayland app-id — used in window rules and dock

  # Default text editor
  editor = "code";
  editorAppId = "code-url-handler"; # Wayland app-id — used in window rules

  # Fonts
  font = {
    mono = "JetBrains Mono";
    size = 13;
  };

  # Theme (Gruvbox)
  theme = "gruvbox-dark-soft";

  # Gruvbox color palette (base16 colors)
  # Used by applications that don't support Stylix theming
  color = {
    # Hard/Background shades
    bg_hard = "#1d2021"; # base00
    bg = "#282828"; # base01
    bg_soft = "#32302f"; # bg0_hard
    bg0 = "#3c3836"; # bg0
    bg1 = "#504945"; # bg1

    # Foreground shades
    fg0 = "#ebdbb2"; # base06 (primary light foreground)
    fg_dark = "#665c54"; # bg3
    fg = "#7c6f64"; # bg4
    fg_light = "#928374"; # gray

    # Accent colors
    red = "#fb4934"; # base08 (bright)
    red_dim = "#cc241d"; # base08 (dim)

    green = "#b8bb26"; # base0B (bright)
    green_dim = "#98971a"; # base0B (dim)

    yellow = "#fabd2f"; # base0A (bright)
    yellow_dim = "#d79921"; # base0A (dim)

    blue = "#83a598"; # base0D (bright)
    blue_dim = "#458588"; # base0D (dim)

    purple = "#d3869b"; # base0E (bright)
    purple_dim = "#b16286"; # base0E (dim)

    aqua = "#8ec07c"; # base0C (bright)
    aqua_dim = "#689d6a"; # base0C (dim)

    orange = "#fe8019"; # base09 (bright)
    orange_dim = "#d65d0e"; # base09 (dim)

    gray = "#928374"; # base04 (bright gray)
    gray_dim = "#a89984"; # base05 (dim gray)
  };

  # Keyboard layout (XKB)
  keyboard = {
    layout = "us,ara";
    variant = ",qwerty";
    options = "grp:caps_toggle,grp_led:caps";
  };

  # Niri compositor extends keyboard options
  keyboardNiriExtra = "terminate:ctrl_alt_bksp";
}
