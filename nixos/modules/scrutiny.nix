# Scrutiny SMART disk health monitoring (localhost:8080).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.scrutiny = {
    enable = lib.mkEnableOption "Scrutiny SMART disk health monitoring dashboard";
  };

  config = lib.mkIf config.mySystem.scrutiny.enable {
    services = {
      scrutiny = {
        enable = true;
        openFirewall = false;

        settings = {
          web.listen = {
            host = "127.0.0.1";
            port = 8080;
          };
          log.level = "INFO";
        };

        collector = {
          enable = true;
          schedule = "daily";
        };
      };

      # Bind InfluxDB backend to localhost
      influxdb2.settings.http-bind-address = "127.0.0.1:8086";
    };

    systemd = {
      services =
        let
          waitScript = pkgs.writeShellScript "wait-for-scrutiny" ''
            for i in $(seq 1 30); do
              ${pkgs.curl}/bin/curl -sf http://127.0.0.1:8080/api/summary >/dev/null 2>&1 && exit 0
              sleep 2
            done
            echo "Scrutiny API not ready after 60s"
            exit 1
          '';
        in
        {
          # Wait for Scrutiny web API before collector runs (prevents boot race condition)
          scrutiny-collector.serviceConfig = {
            ExecStartPre = [ "${waitScript}" ]; # L-05: No + prefix — curl doesn't need root
            PrivateTmp = lib.mkForce true;
            ProtectHome = lib.mkForce true;
            NoNewPrivileges = lib.mkForce true;
            ProtectKernelTunables = lib.mkForce true;
            ProtectControlGroups = lib.mkForce true;
            RestrictSUIDSGID = lib.mkForce true;
            # Collector needs access to /dev for SMART data — no ProtectSystem=strict
          };

          # Retention: purge InfluxDB WAL/data older than 1 year (Scrutiny grows ~1MB/day)
          scrutiny-retention-cleanup = {
            description = "Clean old Scrutiny InfluxDB data";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.findutils}/bin/find /var/lib/influxdb2 -type f -name '*.tsm' -mtime +365 -delete";
            };
          };

          # SECURITY: Systemd hardening + resource limits
          scrutiny.serviceConfig = {
            MemoryMax = "128M";
            MemoryHigh = "96M";
            PrivateTmp = lib.mkForce true;
            ProtectSystem = lib.mkForce "strict";
            ProtectHome = lib.mkForce true;
            NoNewPrivileges = lib.mkForce true;
            ProtectKernelTunables = lib.mkForce true;
            ProtectControlGroups = lib.mkForce true;
            RestrictSUIDSGID = lib.mkForce true;
            ReadWritePaths = [ "/var/lib/scrutiny" ];
          };

          influxdb2.serviceConfig = {
            MemoryMax = "256M";
            MemoryHigh = "192M";
          };
        };

      timers.scrutiny-retention-cleanup = {
        description = "Monthly Scrutiny InfluxDB data cleanup";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
