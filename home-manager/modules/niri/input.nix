{ constants, ... }:
{
  programs.niri.settings.input = {
    keyboard = {
      xkb = {
        inherit (constants.keyboard) layout variant;
        options = "${constants.keyboard.options},${constants.keyboardNiriExtra}";
      };
      repeat-rate = 25;
      repeat-delay = 600;
    };
    touchpad = {
      tap = true;
      natural-scroll = true;
      dwt = true;
      dwtp = true; # Disable-while-trackpointing (ThinkPad essential)
      click-method = "clickfinger"; # Two-finger = right-click
      accel-profile = "adaptive"; # Natural acceleration curve
    };
    trackpoint = {
      accel-speed = 0.4; # Range: -1.0 to 1.0
      accel-profile = "flat"; # No acceleration curve, raw input
    };
    mouse = {
      accel-speed = 0.0;
    };

    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };
    warp-mouse-to-focus.enable = true;
    workspace-auto-back-and-forth = true;
  };
}
