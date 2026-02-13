_: {
  programs.niri.settings.layout = {
    gaps = 8;
    center-focused-column = "on-overflow";

    preset-column-widths = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
    ];

    default-column-width = {
      proportion = 0.5;
    };

    focus-ring.enable = false; # Stylix sets border colors instead

    border = {
      enable = true;
      width = 2;
    };

    struts = { };

    background-color = "transparent"; # Noctalia wallpaper shows through
  };
}
