# ActivityWatch app usage tracking (Wayland, dashboard at localhost:5600).
{ pkgs, ... }:

{
  xdg.configFile."activitywatch/aw-server-rust/config.toml".force = true;

  services.activitywatch = {
    enable = true;
    package = pkgs.aw-server-rust;

    settings = {
      port = 5600;
      host = "127.0.0.1"; # Localhost only — defense-in-depth alongside firewall
    };

    watchers = {
      # Rust-based Wayland window watcher + AFK detection
      awatcher = {
        package = pkgs.awatcher;
        settings = {
          idle-timeout-seconds = 180; # Matches swayidle dim timeout
          poll-time-idle-seconds = 5;
          poll-time-window-seconds = 1;
        };
      };
    };
  };

  systemd.user.services.activitywatch-watcher-awatcher = {
    Unit = {
      After = [
        "graphical-session.target"
        "activitywatch.service"
      ];
      Requires = [ "activitywatch.service" ];
    };
    Service = {
      # awatcher may exit 0 when started before Wayland window protocols are ready.
      # Keep retrying so tracking starts once the compositor session is fully available.
      Restart = "always";
      RestartSec = 5;
    };
  };
}
