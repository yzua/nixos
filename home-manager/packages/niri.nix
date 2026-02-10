# Niri compositor and Wayland utilities.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Clipboard
    cliphist
    wl-clip-persist
    wl-clipboard
    wtype

    # Desktop integration
    libnotify
    playerctl

    # Screenshots
    grim # Wayland screenshot tool (used by swappy pipeline)
    slurp # Region selector for grim

    # Wayland utilities
    bemoji
    brightnessctl
    showmethekey
  ];
}
