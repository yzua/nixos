{
  cfg,
  config,
  lib,
  pkgs,
  logCleanupCommand,
  mkCliAutoupdateScript,
}:
let
  mkWeeklyTimer = description: {
    Unit.Description = description;
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  autoUpdateTools = [
    {
      binary = "claude";
      npmPackage = "@anthropic-ai/claude-code";
      label = "Claude Code CLI";
    }
    {
      binary = "codex";
      npmPackage = "@openai/codex";
      label = "Codex CLI";
    }
    {
      binary = "gemini";
      npmPackage = "@google/gemini-cli";
      label = "Gemini CLI";
    }
  ];

  mkAutoUpdateService =
    {
      binary,
      npmPackage,
      label,
    }:
    {
      Unit.Description = "Auto-update ${label}";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkCliAutoupdateScript { inherit binary npmPackage label; }}";
      };
    };
in
lib.mkIf cfg.logging.enable {
  tmpfiles.rules = [
    "d ${cfg.logging.directory} 0755 - - -"
  ];

  services = {
    ai-agent-log-cleanup = {
      Unit.Description = "Clean up old AI agent logs";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "cleanup" logCleanupCommand}";
      };
    };

    opencode-db-vacuum = {
      Unit.Description = "Vacuum OpenCode SQLite database";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "opencode-vacuum" ''
          DB="${config.xdg.dataHome}/opencode/opencode.db"
          if [[ -f "$DB" ]]; then
            ${pkgs.sqlite}/bin/sqlite3 "$DB" "VACUUM;"
            echo "Vacuumed OpenCode database"
          fi
        ''}";
      };
    };
  }
  // builtins.listToAttrs (
    map (tool: lib.nameValuePair "${tool.binary}-autoupdate" (mkAutoUpdateService tool)) autoUpdateTools
  );

  timers = {
    ai-agent-log-cleanup = mkWeeklyTimer "Weekly AI agent log cleanup";
    opencode-db-vacuum = mkWeeklyTimer "Weekly OpenCode database vacuum";
  }
  // builtins.listToAttrs (
    map (
      tool:
      lib.nameValuePair "${tool.binary}-autoupdate" (mkWeeklyTimer "Weekly ${tool.label} auto-update")
    ) autoUpdateTools
  );
}
