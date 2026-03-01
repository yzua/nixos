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
  workflowPrompts = import ./_workflow-prompts.nix;
  inherit (mcpTransforms) agentLogWrapper;
  commitSplitPrompt = workflowPrompts.commitSplit;
  refactorMaintainabilityPrompt = workflowPrompts.refactorMaintainability;
  securityAuditPrompt = workflowPrompts.securityAudit;
  markdownSyncPrompt = workflowPrompts.markdownSync;

  mkAliasAttrs =
    aliasSpecs:
    builtins.listToAttrs (
      map (spec: {
        name = spec.alias;
        value = spec.command;
      }) aliasSpecs
    );

  aiAgentAliasSpecs = [
    {
      alias = "cl";
      command = "claude --dangerously-skip-permissions";
      workflowPromptMode = "positional";
    }
    {
      alias = "clglm";
      command = "claude_glm";
      workflowPromptMode = "positional";
    }
    {
      alias = "gem";
      command = "gemini --yolo";
    }
    {
      alias = "cx";
      command = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox";
      workflowPromptMode = "positional";
    }
    {
      alias = "oc";
      command = "opencode";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocglm";
      command = "opencode_glm";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocgem";
      command = "opencode_gemini";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocgpt";
      command = "opencode_gpt";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocs";
      command = "opencode_sonnet";
      workflowPromptMode = "flag";
    }
  ];

  workflowPromptSpecs = [
    {
      suffix = "cm";
      prompt = commitSplitPrompt;
    }
    {
      suffix = "rf";
      prompt = refactorMaintainabilityPrompt;
    }
    {
      suffix = "sa";
      prompt = securityAuditPrompt;
    }
    {
      suffix = "md";
      prompt = markdownSyncPrompt;
    }
  ];

  workflowAgentSpecs = builtins.filter (agent: agent ? workflowPromptMode) aiAgentAliasSpecs;

  aiWorkflowAliasSpecs = lib.flatten (
    map (
      workflow:
      map (agent: {
        alias = "${agent.alias}${workflow.suffix}";
        command =
          if agent.workflowPromptMode == "flag" then
            "${agent.command} --prompt '${workflow.prompt}'"
          else
            "${agent.command} '${workflow.prompt}'";
      }) workflowAgentSpecs
    ) workflowPromptSpecs
  );

  aiAliases = mkAliasAttrs (aiAgentAliasSpecs ++ aiWorkflowAliasSpecs);
in
{
  config = lib.mkIf cfg.enable (
    let
      shellAliases =
        (
          if cfg.logging.enable then
            {
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
            }
          else
            { }
        )
        // aiAliases
        // {
          "ai-mcp-scan" = "uvx mcp-scan@latest --skills";
        };
    in
    {
      home.packages = [
        agentLogWrapper
      ]
      ++ (lib.optional cfg.logging.enable (
        pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
          find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
          echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
        ''
      ));

      programs.zsh.shellAliases = shellAliases;
      programs.bash.shellAliases = shellAliases;

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

        services.opencode-db-vacuum = {
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

        timers.opencode-db-vacuum = {
          Unit.Description = "Weekly OpenCode database vacuum";
          Timer = {
            OnCalendar = "weekly";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    }
  );
}
