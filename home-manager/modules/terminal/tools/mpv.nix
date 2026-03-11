# mpv media player with Vim keybindings and stable rendering defaults.
{ constants, ... }:

let
  seekBindings = [
    {
      key = "l";
      seconds = 5;
    }
    {
      key = "h";
      seconds = -5;
    }
    {
      key = "j";
      seconds = -60;
    }
    {
      key = "k";
      seconds = 60;
    }
  ];

  generatedSeekBindings = builtins.listToAttrs (
    map (binding: {
      name = binding.key;
      value = "seek ${toString binding.seconds}";
    }) seekBindings
  );
in

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
    bindings = generatedSeekBindings;
  };
}
