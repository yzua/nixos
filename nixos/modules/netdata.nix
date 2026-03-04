{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:

let
  hardening = import ./helpers/_systemd-hardening.nix { inherit lib; };
in
{
  options.mySystem.netdata = {
    enable = lib.mkEnableOption "Netdata real-time system monitoring dashboard";
  };

  config = lib.mkIf config.mySystem.netdata.enable {
    services.netdata = {
      enable = true;
      package = pkgs.netdataCloud;

      config = {
        global = {
          "bind to" = "127.0.0.1";
          "default port" = "19999";
          "memory mode" = "dbengine";
          "page cache size" = "64";
          "dbengine multihost disk space" = "512";
        };

        web."enable gzip compression" = "yes";
        cloud."enabled" = "no";
        logs."level" = "error";

        "plugin:ioping"."enabled" = "no";
        "plugin:perf"."enabled" = "no";
        "plugin:freeipmi"."enabled" = "no";
        "plugin:otel"."enabled" = "no";
        "plugin:logs-management"."enabled" = "no";
        "plugin:charts.d"."enabled" = "no";
        "plugin:python.d"."enabled" = "no";
      };

      enableAnalyticsReporting = false;

      configDir = {
        "health.d/timex.conf" = pkgs.writeText "netdata-timex.conf" ''
                alarm: system_clock_sync_state
                   on: system.clock_sync_state
                class: Errors
                 type: System
            component: Clock
          host labels: _os=linux
                 calc: $state
                units: synchronization state
                every: 10s
                 warn: $this != $this
                delay: down 5m
              summary: System clock sync state
                 info: When set to 0, the system kernel believes the system clock is not properly synchronized to a reliable server
                   to: silent
        '';
      };
    };

    users.users.netdata.extraGroups = [
      "systemd-journal"
    ]
    ++ lib.optionals config.virtualisation.docker.enable [ "docker" ];

    systemd.services.netdata.serviceConfig = hardening.mkOneshotHardening {
      protectHome = true;
      protectSystem = "full";
      memoryMax = "512M";
      memoryHigh = "384M";
      useMkForce = true;
    };

    environment.systemPackages = [ pkgsStable.smartmontools ];
  };
}
