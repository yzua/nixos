# Niri compositor, Wayland utilities, and GNOME helpers (minimal set — GNOME desktop disabled).

{ pkgs, ... }:

{
  home.packages = with pkgs; [
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

    # GNOME utilities for Niri
    gnome-disk-utility
    gnome-text-editor
  ];
}
