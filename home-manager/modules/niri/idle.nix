# Idle management (swayidle) — ported from Hypridle.
# Chain: 3min dim → 8min lock (Noctalia) → 20min DPMS off.

{ config, pkgs, ... }:

{
  services.swayidle = {
    enable = true;

    timeouts = [
      # Dim screen after 3 minutes of inactivity
      {
        timeout = 180;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 30";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }

      # Lock screen after 8 minutes (via Noctalia lock screen)
      {
        timeout = 480;
        command = "${config.home.profileDirectory}/bin/noctalia-shell ipc call lockScreen lock";
      }

      # Turn off displays after 20 minutes
      {
        timeout = 1200;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ];

    events = {
      # Lock before sleep
      before-sleep = "${config.home.profileDirectory}/bin/noctalia-shell ipc call lockScreen lock";
      # Handle loginctl lock-session
      lock = "${pkgs.cliphist}/bin/cliphist wipe && ${config.home.profileDirectory}/bin/noctalia-shell ipc call lockScreen lock";
    };
  };
}
