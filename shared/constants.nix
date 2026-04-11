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
  editorAppId = "code|Code|code-url-handler"; # Wayland app-id — used in window rules (lowercase for vscode-fhs, Code for upstream, code-url-handler for URL opens)

  # Fonts
  font = {
    mono = "JetBrains Mono";
    monoNerd = "JetBrainsMono Nerd Font";
    size = 13;
    sizeApplications = 11;
  };

  # Theme (GruvboxAlt)
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
    outline = "#57514e"; # GruvboxAlt outline/border

    # Foreground shades
    fg0 = "#ebdbb2"; # base06 (primary light foreground)
    fg_dark = "#665c54"; # bg3
    fg = "#7c6f64"; # bg4

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
    niriExtra = "terminate:ctrl_alt_bksp";
  };

  # Mullvad SOCKS5 proxy endpoints for browser profiles.
  # Never mix proxies - each profile gets a dedicated exit.
  proxies = {
    # LibreWolf profiles
    librewolf = {
      personal = "se-sto-wg-socks5-002.relays.mullvad.net"; # Sweden
      work = "de-fra-wg-socks5-003.relays.mullvad.net"; # Germany
      banking = "nl-ams-wg-socks5-005.relays.mullvad.net"; # Netherlands
      shopping = "ro-buh-wg-socks5-001.relays.mullvad.net"; # Romania
      illegal = "ch-zrh-wg-socks5-002.relays.mullvad.net"; # Switzerland
    };
    brave = {
      personal = "fi-hel-wg-socks5-001.relays.mullvad.net"; # Finland
    };
    # I2P local daemon
    i2pd = "127.0.0.1"; # Local I2P daemon (port 4447)
  };

  # External service API endpoints.
  services = {
    zai = {
      apiRoot = "https://api.z.ai/api"; # Z.AI API root (Anthropic-compatible + MCP)
    };
  };
}
