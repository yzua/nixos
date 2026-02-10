# GNOME utilities used with Niri (minimal set — GNOME desktop disabled).
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    gnome-disk-utility
    gnome-text-editor
  ];
}
