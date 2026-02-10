# Netdata real-time system monitoring dashboard (localhost:19999).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.netdata = {
    enable = lib.mkEnableOption "Netdata real-time system monitoring dashboard";
  };

  config = lib.mkIf config.mySystem.netdata.enable {
    services.netdata = {
      enable = true;
      # netdataCloud includes local web dashboard (v3); telemetry disabled below
      package = pkgs.netdataCloud;

      config = {
        global = {
          "bind to" = "127.0.0.1";
          "default port" = "19999";
          "memory mode" = "dbengine";
          "page cache size" = "64"; # MB
          "dbengine multihost disk space" = "512"; # MB (~7 days)
        };

        web."enable gzip compression" = "yes";
        cloud."enabled" = "no";
        logs."level" = "warning";

        # Disable plugins that fail or are unneeded on hardened NixOS desktop
        "plugin:ioping"."enabled" = "no";
        "plugin:perf"."enabled" = "no";
        "plugin:freeipmi"."enabled" = "no"; # No IPMI hardware
        "plugin:otel"."enabled" = "no"; # OpenTelemetry not configured
        "plugin:logs-management"."enabled" = "no"; # Missing binary in Nix wrapper
        "plugin:charts.d"."enabled" = "no"; # No bash collectors configured
        "plugin:python.d"."enabled" = "no"; # Missing deps (haproxy, traefik unused)
      };

      enableAnalyticsReporting = false;
    };

    users.users.netdata.extraGroups = [
      "systemd-journal"
    ]
    ++ lib.optionals config.virtualisation.docker.enable [ "docker" ];

    # SECURITY: Systemd hardening directives + resource limits
    # mkForce on directives that conflict with upstream nixpkgs netdata module
    systemd.services.netdata.serviceConfig = {
      MemoryMax = "512M";
      MemoryHigh = "384M";
      PrivateTmp = lib.mkForce true;
      ProtectSystem = lib.mkForce "full"; # "full" not "strict" — Netdata needs /proc, /sys read access
      ProtectHome = lib.mkForce true;
      NoNewPrivileges = lib.mkForce true;
      ProtectKernelTunables = lib.mkForce true;
      ProtectControlGroups = lib.mkForce true;
      RestrictSUIDSGID = lib.mkForce true;
    };

    environment.systemPackages = [ pkgs.smartmontools ];
  };
}
