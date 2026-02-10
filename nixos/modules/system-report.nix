# Unified system health reporting (hourly errors, daily full, weekly cleanup).
{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  cfg = config.mySystem.systemReport;

  featureFlags = {
    HAS_PROMETHEUS = lib.boolToString config.mySystem.observability.enable;
    HAS_LOKI = lib.boolToString config.mySystem.loki.enable;
    HAS_NETDATA = lib.boolToString config.mySystem.netdata.enable;
    HAS_SCRUTINY = lib.boolToString config.mySystem.scrutiny.enable;
    HAS_OPENSNITCH = lib.boolToString config.mySystem.opensnitch.enable;
    HAS_FAIL2BAN = lib.boolToString config.mySystem.auditLogging.enable;
    SYSTEM_REPORT_DIR = cfg.outputDir;
    REPORT_USER = user;
  };

  featureFlagExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "export ${k}=\"\${${k}:-${v}}\"") featureFlags
  );

  reportScript = pkgs.writeShellApplication {
    name = "system-report";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        inetutils # hostname command
        jq
        curl
        systemd
        gawk
        gnused
        findutils
        bc
        gnugrep
      ]
      ++ lib.optionals config.services.vnstat.enable [ pkgs.vnstat ]
      ++ lib.optionals config.mySystem.auditLogging.enable [ pkgs.fail2ban ];
    text = featureFlagExports + "\n" + builtins.readFile ../../scripts/system/system-report.sh;
  };
in
{
  options.mySystem.systemReport = {
    enable = lib.mkEnableOption "unified system health reporting";
    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/system-report";
      description = "Directory for report output.";
    };
    retentionDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Days to keep historical reports.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ reportScript ];

    systemd = {
      services = {
        system-report-errors = {
          description = "Quick system error scan";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${reportScript}/bin/system-report errors";
            # SECURITY: Systemd hardening directives
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            NoNewPrivileges = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            ReadWritePaths = [ cfg.outputDir ];
          };
        };

        system-report-full = {
          description = "Full system health report";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${reportScript}/bin/system-report full";
            # SECURITY: Systemd hardening directives
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            NoNewPrivileges = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            ReadWritePaths = [ cfg.outputDir ];
          };
        };

        system-report-cleanup = {
          description = "Clean up old system reports";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.findutils}/bin/find ${cfg.outputDir}/history -type f -mtime +${toString cfg.retentionDays} -delete";
            # SECURITY: Systemd hardening directives
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            NoNewPrivileges = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            ReadWritePaths = [ cfg.outputDir ];
          };
        };
      };

      timers = {
        system-report-errors = {
          description = "Hourly system error scan";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "hourly";
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        system-report-full = {
          description = "Daily full system health report";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "06:00";
            Persistent = true;
            RandomizedDelaySec = "15m";
          };
        };

        system-report-cleanup = {
          description = "Weekly cleanup of old system reports";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      };

      tmpfiles.rules = [
        "d ${cfg.outputDir} 0755 root root -"
        "d ${cfg.outputDir}/history 0755 root root -"
      ];
    };
  };
}
