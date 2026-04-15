# Shared Wayland Chromium-family browser wrapper flags.
# Usage: inherit (import ./_mk-wayland-browser-wrapper.nix) mkWaylandBrowserWrapper;

let
  waylandFlags = [
    "--ozone-platform=wayland"
    "--enable-wayland-ime"
    "--wayland-text-input-version=3"
    "--password-store=basic"
  ];
in
{
  mkWaylandBrowserWrapper =
    {
      bin,
      extraFlags ? [ ],
    }:
    let
      allFlags = waylandFlags ++ extraFlags;
    in
    {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec ${bin} ${builtins.concatStringsSep " " allFlags} "$@"
      '';
    };
}
