# Generate Noctalia GruvboxAlt color scheme from shared constants.
# Dark scheme: fully derived from constants.nix (single source of truth).
# Light scheme: uses constants where possible, with light-mode-specific values for unused palette entries.

{ constants }:

let
  c = constants.color;

  # Gruvbox light-mode values not in constants (not in active use, darkMode = true).
  lightOutline = "#bdae93"; # Gruvbox light base03
  lightShadow = "#d5c4a1"; # Gruvbox light base02
  lightCursorText = "#625e5c"; # Gruvbox light cursor text
  lightFadedRed = "#9d0006";
  lightFadedGreen = "#79740e";
  lightFadedYellow = "#b57614";
  lightFadedBlue = "#076678";
  lightFadedMagenta = "#8f3f71";
  lightFadedCyan = "#427b58";
in
builtins.toJSON {
  dark = {
    mPrimary = c.fg0;
    mOnPrimary = c.bg;
    mSecondary = c.aqua;
    mOnSecondary = c.bg;
    mTertiary = c.blue;
    mOnTertiary = c.bg;
    mError = c.red;
    mOnError = c.bg;
    mSurface = c.bg;
    mOnSurface = c.fg_light;
    mSurfaceVariant = c.bg0;
    mOnSurfaceVariant = c.fg0;
    mOutline = c.outline;
    mShadow = c.bg;
    mHover = c.blue;
    mOnHover = c.bg;
    terminal = {
      foreground = c.fg0;
      background = c.bg;
      selectionFg = c.fg0;
      selectionBg = c.fg_dark;
      cursorText = c.bg;
      cursor = c.fg0;
      normal = {
        black = c.bg;
        red = c.red_dim;
        green = c.green_dim;
        yellow = c.yellow_dim;
        blue = c.blue_dim;
        magenta = c.purple_dim;
        cyan = c.aqua_dim;
        white = c.gray_dim;
      };
      bright = {
        black = c.gray;
        inherit (c)
          red
          green
          yellow
          blue
          ;
        magenta = c.purple;
        cyan = c.aqua;
        white = c.fg0;
      };
    };
  };

  light = {
    mPrimary = c.bg0;
    mOnPrimary = c.fg_light;
    mSecondary = c.aqua_dim;
    mOnSecondary = c.fg_light;
    mTertiary = c.blue_dim;
    mOnTertiary = c.fg_light;
    mError = c.red_dim;
    mOnError = c.fg_light;
    mSurface = c.fg_light;
    mOnSurface = c.bg0;
    mSurfaceVariant = c.fg0;
    mOnSurfaceVariant = c.fg;
    mOutline = lightOutline;
    mShadow = lightShadow;
    mHover = c.blue_dim;
    mOnHover = c.fg_light;
    terminal = {
      foreground = c.bg0;
      background = c.fg_light;
      selectionFg = c.fg_light;
      selectionBg = c.bg0;
      cursorText = lightCursorText;
      cursor = c.bg0;
      normal = {
        black = c.fg_light;
        red = c.red_dim;
        green = c.green_dim;
        yellow = c.yellow_dim;
        blue = c.blue_dim;
        magenta = c.purple_dim;
        cyan = c.aqua_dim;
        white = c.fg;
      };
      bright = {
        black = c.gray;
        red = lightFadedRed;
        green = lightFadedGreen;
        yellow = lightFadedYellow;
        blue = lightFadedBlue;
        magenta = lightFadedMagenta;
        cyan = lightFadedCyan;
        white = c.bg0;
      };
    };
  };
}
