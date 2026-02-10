# XDG Desktop Portal packages and session variables.
{ pkgs, ... }:

{
  # niri-flake auto-adds xdg-desktop-portal-gnome + configPackages
  environment = {
    systemPackages = with pkgs; [
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-utils
    ];

    sessionVariables = {
      GTK_USE_PORTAL = "0";
      GDK_DEBUG = "none";
      NO_AT_BRIDGE = "1";
    };
  };
}
