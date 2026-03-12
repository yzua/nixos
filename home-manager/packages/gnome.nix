# GNOME utilities used with Niri (minimal set — GNOME desktop disabled).
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gnome-disk-utility
    gnome-text-editor
  ];
}
