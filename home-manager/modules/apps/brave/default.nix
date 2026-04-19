# Brave browser with proxy and declarative extensions.
# Uses Finland proxy - different from LibreWolf's Sweden. Never mix proxies.

{
  constants,
  pkgs,
  ...
}:
let
  inherit (import ../_mk-wayland-browser-wrapper.nix) mkWaylandBrowserWrapper;
  inherit (constants.proxies) brave;
in
{
  imports = [
    ./extensions.nix # Declarative extension install list
  ];

  programs.brave = {
    enable = true;
    package = pkgs.brave;
  };

  home.file.".local/bin/brave" = mkWaylandBrowserWrapper {
    bin = "${pkgs.brave}/bin/brave";
  };

  # Proxy launcher - Finland via Mullvad SOCKS5
  home.file.".local/bin/brave-proxy" = mkWaylandBrowserWrapper {
    bin = "${pkgs.brave}/bin/brave";
    extraFlags = [ ''--proxy-server="socks5://${brave.personal}:${toString constants.ports.socks}"'' ];
  };
}
