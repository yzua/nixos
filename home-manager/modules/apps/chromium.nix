# Chromium launch wrapper with Wayland crash workaround.

{ pkgs, ... }:

{
  home.file.".local/bin/chromium" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.ungoogled-chromium}/bin/chromium \
        --ozone-platform=x11 \
        --password-store=basic \
        "$@"
    '';
  };
}
