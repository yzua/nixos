{
  cfg,
  config,
  lib,
  pkgs,
  logCleanupCommand,
  mkCliAutoupdateScript,
  mkWeeklyTimer,
}:
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

    claude-autoupdate = {
      Unit.Description = "Auto-update Claude Code CLI";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkCliAutoupdateScript {
          binary = "claude";
          npmPackage = "@anthropic-ai/claude-code";
          label = "Claude Code CLI";
        }}";
      };
    };

    codex-autoupdate = {
      Unit.Description = "Auto-update Codex CLI";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkCliAutoupdateScript {
          binary = "codex";
          npmPackage = "@openai/codex";
          label = "Codex CLI";
        }}";
      };
    };

    gemini-autoupdate = {
      Unit.Description = "Auto-update Gemini CLI";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkCliAutoupdateScript {
          binary = "gemini";
          npmPackage = "@google/gemini-cli";
          label = "Gemini CLI";
        }}";
      };
    };
  };

  timers = {
    ai-agent-log-cleanup = mkWeeklyTimer "Weekly AI agent log cleanup";
    opencode-db-vacuum = mkWeeklyTimer "Weekly OpenCode database vacuum";
    claude-autoupdate = mkWeeklyTimer "Weekly Claude Code CLI auto-update";
    codex-autoupdate = mkWeeklyTimer "Weekly Codex CLI auto-update";
    gemini-autoupdate = mkWeeklyTimer "Weekly Gemini CLI auto-update";
  };
}
