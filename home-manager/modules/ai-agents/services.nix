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
  commitSplitPrompt = "Review all current git changes, propose a commit plan that splits work into minimal logical commits, then execute it commit-by-commit using signed commits (git commit -S). For each commit, stage only relevant hunks/files, run relevant checks for touched files, and use a clear conventional commit message. Show the plan before creating the first commit.";
  refactorMaintainabilityPrompt = "Analyze this repository and perform a maintainability-focused refactor with zero behavior regressions. Detect the active languages, frameworks, and conventions first, then identify duplicated logic, oversized files/functions, mixed responsibilities, weak module boundaries, dead code, and non-idiomatic patterns for each language. Create a prioritized plan by impact and risk with concrete file-level actions before editing. Implement changes in small atomic steps that preserve external behavior and public APIs unless a migration is explicitly required. Split code into coherent modules where responsibilities are mixed, extract reusable utilities only when duplication is real, and align naming, structure, error handling, and testing patterns with project conventions for each tech stack. Remove bad practices and generic boilerplate, avoid broad rewrites, and avoid placeholder TODO solutions. After each step run relevant formatter, linter, type-check, and tests for touched files and fix all findings. Finish with a concise report of what was split, what duplication was removed, what remains risky, and the next highest-value refactors.";
  securityAuditPrompt = "Perform a comprehensive security audit for this repository with evidence-based findings only. First detect languages, frameworks, runtimes, dependency managers, deployment files, and trust boundaries. Build a threat model that covers authentication and authorization, input validation, injection risks, command execution, SSRF, path traversal, XSS, CSRF, open redirects, unsafe deserialization, insecure cryptography, secret leakage, dependency and supply-chain risk, CI and CD hardening, container and IaC misconfiguration, and least-privilege violations. Review code, configs, scripts, and docs; report concrete vulnerabilities with severity, exploitability, impact, and exact file paths and lines. Prioritize critical and high findings, then medium and low. For each finding propose minimal idiomatic fixes that match the project stack and include verification steps and tests. Avoid generic advice and avoid speculative findings without repository evidence. Preserve behavior unless an explicit fix requires a controlled change. Finish with a remediation plan ordered by risk, quick wins, and long-term hardening tasks.";
  markdownSyncPrompt = "Audit project documentation for accuracy and freshness, then update it to match the current repository state. Focus on README.md, AGENTS.md files, and all markdown under docs and module directories. Verify every documented command, workflow, path, option, feature, dependency, and architecture claim against real code, scripts, flake outputs, module imports, and current project structure. Flag and fix outdated, ambiguous, or contradictory statements. Remove stale references, missing steps, and copy paste drift. Ensure instructions are actionable, deterministic, and aligned with current tooling and conventions by language and framework. Keep edits precise and minimal while improving clarity and maintainability. Prefer concrete paths and exact command examples. Preserve intentional project specific guidance and scope rules from AGENTS files. At the end, summarize what changed, what was verified, and any remaining documentation gaps that still require human decisions.";

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
      (if cfg.logging.enable then
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
        { })
      // aiAliases
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
  };
}
