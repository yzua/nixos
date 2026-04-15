# Chromium launch wrapper with Wayland-native support.

{ pkgs, ... }:

let
  inherit (import ./_mk-wayland-browser-wrapper.nix) mkWaylandBrowserWrapper;
in
{
  home.file.".local/bin/chromium" = mkWaylandBrowserWrapper {
    bin = "${pkgs.ungoogled-chromium}/bin/chromium";
  };
}
