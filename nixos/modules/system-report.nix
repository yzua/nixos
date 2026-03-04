# Unified system health reporting (hourly errors, daily full, weekly cleanup).
{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  inherit (import ./_systemd-hardening.nix { inherit lib; }) mkOneshotHardening;

  cfg = config.mySystem.systemReport;

  # Standard hardening for system-report services
  reportHardening = mkOneshotHardening { readWritePaths = [ cfg.outputDir ]; };

  featureFlags = {
    HAS_PROMETHEUS = lib.boolToString config.mySystem.observability.enable;
    HAS_LOKI = lib.boolToString config.mySystem.loki.enable;
    HAS_NETDATA = lib.boolToString config.mySystem.netdata.enable;
    HAS_SCRUTINY = lib.boolToString config.mySystem.scrutiny.enable;
    HAS_OPENSNITCH = lib.boolToString config.mySystem.opensnitch.enable;
    HAS_FAIL2BAN = lib.boolToString config.mySystem.auditLogging.enable;
    SYSTEM_REPORT_DIR = cfg.outputDir;
    REPORT_USER = user;
    SYSTEM_REPORT_HELPERS = ../../scripts/system/report-helpers.sh;
    SYSTEM_REPORT_COLLECTORS = ../../scripts/system/report-collectors.sh;
    AI_AGENT_LOG_DIR = "/home/${user}/.local/share/ai-agents/logs";
  };

  featureFlagExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "export ${k}=\"\${${k}:-${v}}\"") featureFlags
  );

  reportScriptBase = pkgs.writeShellApplication {
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

  mkReportService = description: execStart: {
    inherit description;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = execStart;
    }
    // reportHardening;
  };

  mkReportTimer = description: onCalendar: randomizedDelaySec: {
    inherit description;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = onCalendar;
      Persistent = true;
      inherit randomizedDelaySec;
    };
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
    environment.systemPackages = [ reportScriptBase ];

    systemd = {
      services = {
        system-report-errors = mkReportService "Quick system error scan" "${reportScriptBase}/bin/system-report errors";

        system-report-full = mkReportService "Full system health report" "${reportScriptBase}/bin/system-report full";

        system-report-cleanup = mkReportService "Clean up old system reports" "${pkgs.findutils}/bin/find ${cfg.outputDir}/history -type f -mtime +${toString cfg.retentionDays} -delete";
      };

      timers = {
        system-report-errors = mkReportTimer "Hourly system error scan" "hourly" "5m";

        system-report-full = mkReportTimer "Daily full system health report" "06:00" "15m";

        system-report-cleanup = mkReportTimer "Weekly cleanup of old system reports" "weekly" "1h";
      };

      tmpfiles.rules = [
        "d ${cfg.outputDir} 0755 root root -"
        "d ${cfg.outputDir}/history 0755 root root -"
      ];
    };
  };
}
