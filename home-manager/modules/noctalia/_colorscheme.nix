# Generate Noctalia GruvboxAlt dark color scheme from shared constants.
# darkMode is always true — see settings.nix.

{ constants }:

let
  c = constants.color;
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
}
