# Brave browser with proxy and declarative extensions.
# Uses Finland proxy - different from LibreWolf's Sweden. Never mix proxies.
{
  constants,
  pkgs,
  ...
}:
let
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

  # Proxy launcher - Finland via Mullvad SOCKS5
  home.file.".local/bin/brave-proxy" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.brave}/bin/brave \
        --proxy-server="socks5://${brave.personal}:1080" \
        "$@"
    '';
  };
}
