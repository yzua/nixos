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

  # Stable launch wrapper: avoid Wayland broken pipe crashes + KWallet DBus noise.
  home.file.".local/bin/brave" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.brave}/bin/brave \
        --ozone-platform=x11 \
        --password-store=basic \
        "$@"
    '';
  };

  # Proxy launcher - Finland via Mullvad SOCKS5
  home.file.".local/bin/brave-proxy" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.brave}/bin/brave \
        --ozone-platform=x11 \
        --password-store=basic \
        --proxy-server="socks5://${brave.personal}:1080" \
        "$@"
    '';
  };
}
