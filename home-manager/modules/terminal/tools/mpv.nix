# mpv media player with Vim keybindings and stable rendering defaults.
{ constants, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      gpu-api = "opengl";
      hwdec = "auto-copy-safe";
      vo = "gpu";
      keep-open = true;
      osd-font = constants.font.mono;
      osd-font-size = 24;
      sub-auto = "fuzzy";
      sub-font = "Noto Sans";
      sub-font-size = 40;
      screenshot-directory = "~/Screens";
      screenshot-format = "png";
    };
    bindings = {
      l = "seek 5";
      h = "seek -5";
      j = "seek -60";
      k = "seek 60";
    };
  };
}
