# Zsh aliases, systemd user services/timers, and packages for AI agents.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  mcpTransforms = import ./_mcp-transforms.nix { inherit config lib pkgs; };
  inherit (mcpTransforms) agentLogWrapper;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      agentLogWrapper
      pkgs.tmux
      pkgs.zig
      pkgs.rustfmt
    ]
    ++ (lib.optional cfg.logging.enable (
      pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
        find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
        echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
      ''
    ));

    programs.zsh.shellAliases =
      (lib.mkIf cfg.logging.enable {
        "cl-log" = "ai-agent-log-wrapper claude claude";
        "oc-log" = "ai-agent-log-wrapper opencode opencode";
        "oc-port" = "opencode --port 4096";
        "codex-log" = "ai-agent-log-wrapper codex codex";
        "gemini-log" = "ai-agent-log-wrapper gemini gemini";

        "ai-logs" = "tail -f ~/.local/share/opencode/log/*.log ~/.codex/log/*.log 2>/dev/null";
        "ai-errors" =
          "grep -rn --color=always -i 'error\\|panic\\|fatal\\|exception' ~/.local/share/opencode/log/ ~/.codex/log/ 2>/dev/null | tail -50";

        "ai-stats" = "ai-agent-analyze stats";
        "ai-report" = "ai-agent-analyze report";
        "ai-dash" = "ai-agent-dashboard";
      })
      // {
        "ai-mcp-scan" = "uvx mcp-scan@latest --skills";
      };

    systemd.user = lib.mkIf cfg.logging.enable {
      # Create log directory declaratively (replaces createAiAgentLogDir activation script)
      tmpfiles.rules = [
        "d ${cfg.logging.directory} 0755 - - -"
      ];

      services.ai-agent-log-cleanup = {
        Unit.Description = "Clean up old AI agent logs";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScript "cleanup" ''
            find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
          ''}";
        };
      };

      timers.ai-agent-log-cleanup = {
        Unit.Description = "Weekly AI agent log cleanup";
        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
