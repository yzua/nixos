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
  buildPerformancePrompt = workflowPrompts.buildPerformance;
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
      alias = "clu";
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
      alias = "cxu";
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
    {
      alias = "oczen";
      command = "opencode_zen";
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
      suffix = "bp";
      prompt = buildPerformancePrompt;
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

  workflowClipboardAliasSpecs = map (workflow: {
    alias = "cp${workflow.suffix}";
    command =
      "if command -v wl-copy >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg workflow.prompt} | wl-copy; "
      + "elif command -v xclip >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg workflow.prompt} | xclip -selection clipboard; "
      + "else echo 'Clipboard tool not found (need wl-copy or xclip)' >&2; false; fi "
      + "&& echo 'Copied ${workflow.suffix} prompt to clipboard'";
  }) workflowPromptSpecs;

  aiAliases = mkAliasAttrs (aiAgentAliasSpecs ++ aiWorkflowAliasSpecs ++ workflowClipboardAliasSpecs);
  logCleanupCommand = ''
    find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
  '';

  mkWeeklyTimer = description: {
    Unit.Description = description;
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
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
              "ai-errors-all" =
                "grep -rn --color=always -i 'error\\|panic\\|fatal\\|exception' ~/.local/share/opencode/log/ ~/.codex/log/ 2>/dev/null | tail -100";
              "ai-errors" =
                "grep -rn --color=always -i 'error\\|panic\\|fatal\\|exception' ~/.local/share/opencode/log/ ~/.codex/log/ 2>/dev/null | grep -vi 'Method not found: prompts/list\\|Method not found: resources/list\\|Method not found failed to get prompts' | tail -50";
              "ai-errors-runtime" =
                "grep -rn --color=always -i 'not connected failed to get prompts\\|EIO: i/o error\\|setRawMode failed\\|tui bootstrap failed\\|bun info failed' ~/.local/share/opencode/log/ ~/.codex/log/ 2>/dev/null | tail -50";

              "ai-stats" = "ai-agent-analyze stats";
              "ai-report" = "ai-agent-analyze report";
              "ai-dash" = "ai-agent-dashboard";
            }
          else
            { }
        )
        // aiAliases
        // {
          "ai-mcp-scan" =
            "echo 'mcp-scan package is unavailable; running health checks instead' && ai-mcp-health";
          "ai-mcp-health" =
            "(command -v node >/dev/null && command -v bun >/dev/null && command -v bunx >/dev/null && command -v uvx >/dev/null && gh auth status >/dev/null 2>&1 && [ -f ~/.mcp.json ] && jq -e . ~/.mcp.json >/dev/null && ! grep -q '__GITHUB_TOKEN_PLACEHOLDER__' ~/.mcp.json && echo 'MCP health: ok') || (echo 'MCP health: check failed' && false)";
        };
    in
    {
      home.packages = [
        agentLogWrapper
      ]
      ++ (lib.optional cfg.logging.enable (
        pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
          ${logCleanupCommand}
          echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
        ''
      ));

      programs.zsh.shellAliases = shellAliases;
      programs.bash.shellAliases = shellAliases;

      systemd.user = lib.mkIf cfg.logging.enable {
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

          codex-autoupdate = {
            Unit.Description = "Auto-update Codex CLI";
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScript "codex-autoupdate" ''
                if command -v codex >/dev/null 2>&1; then
                  bun install -g @openai/codex@latest
                  echo "Updated Codex CLI"
                fi
              ''}";
            };
          };
        };

        timers = {
          ai-agent-log-cleanup = mkWeeklyTimer "Weekly AI agent log cleanup";
          opencode-db-vacuum = mkWeeklyTimer "Weekly OpenCode database vacuum";
          codex-autoupdate = mkWeeklyTimer "Weekly Codex CLI auto-update";
        };
      };
    }
  );
}
