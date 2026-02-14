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
      GDK_DEBUG = "none";
      NO_AT_BRIDGE = "1";
    };
  };
}
