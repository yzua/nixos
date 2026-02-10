# Libinput touchpad, mouse, and touch device handling.
_:

{
  services.libinput = {
    enable = true;

    # TrackPoint scroll emulation (middle-button + TrackPoint = scroll)
    mouse = {
      middleEmulation = true;
      scrollMethod = "button";
      scrollButton = 2; # BTN_MIDDLE
    };
  };
}
