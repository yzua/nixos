# Netdata real-time system monitoring dashboard

{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:

let
  inherit (import ./helpers/_systemd-helpers.nix { inherit lib; }) mkOneshotHardening;
in
{
  options.mySystem.netdata = {
    enable = lib.mkEnableOption "Netdata real-time system monitoring dashboard";
  };

  config = lib.mkIf config.mySystem.netdata.enable {
    services.netdata = {
      enable = true;
      package = pkgsStable.netdataCloud;

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
        "plugin:apps"."enabled" = "no"; # Needs CAP_SYS_PTRACE — blocked by NoNewPrivileges hardening
        "plugin:debugfs"."enabled" = "no"; # Needs capabilities — blocked by hardening
        "plugin:systemd-journal"."enabled" = "no"; # Needs capabilities — blocked by hardening
        "plugin:network-viewer"."enabled" = "no"; # Needs capabilities — blocked by hardening
      };

      enableAnalyticsReporting = false;

      configDir = {
        # Disable go.d collectors that auto-detect but can't connect
        "go.d/redis.conf" = pkgs.writeText "netdata-go-redis.conf" ''
          autodetection_retry: 0
          jobs: []
        '';
        "go.d/docker.conf" = pkgs.writeText "netdata-go-docker.conf" ''
          autodetection_retry: 0
          jobs: []
        '';
        "go.d/postgres.conf" = pkgs.writeText "netdata-go-postgres.conf" ''
          autodetection_retry: 0
          jobs: []
        '';
        "go.d/prometheus.conf" = pkgs.writeText "netdata-go-prometheus.conf" ''
          autodetection_retry: 0
          jobs: []
        '';

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

    systemd.services.netdata.serviceConfig = mkOneshotHardening {
      protectHome = true;
      protectSystem = "full";
      memoryMax = "512M";
      memoryHigh = "384M";
      useMkForce = true;
    };

    environment.systemPackages = [ pkgsStable.smartmontools ];
  };
}
