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
      alias = "ocl";
      command = "claude --dangerously-skip-permissions --model opus";
      workflowPromptMode = "positional";
    }
    {
      alias = "hcl";
      command = "claude --dangerously-skip-permissions --model haiku";
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
      alias = "lcx";
      command = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "mcx";
      command = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "hcx";
      command = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "xcx";
      command = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'";
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
      alias = "locgpt";
      command = "opencode_gpt --model openai/gpt-5.3-codex-spark";
      workflowPromptMode = "flag";
    }
    {
      alias = "mocgpt";
      command = "opencode_gpt --model openai/gpt-5.3-codex";
      workflowPromptMode = "flag";
    }
    {
      alias = "hocgpt";
      command = "opencode_gpt --model openai/gpt-5.4";
      workflowPromptMode = "flag";
    }
    {
      alias = "xocgpt";
      command = "opencode_gpt --model openai/gpt-5.1-codex-max";
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
  aiAgentLauncher = pkgs.writeShellScriptBin "ai-agent-launcher" ''
    set -euo pipefail

    if ! command -v fzf >/dev/null 2>&1; then
      echo "Error: fzf is required" >&2
      exit 1
    fi

    pick() {
      local header="$1"
      shift
      printf '%s\n' "$@" | fzf --height=50% --reverse --header="$header"
    }

    usage() {
      echo "Usage: ai-agent-launcher [-s|--simple]"
      echo "  default: sectioned mode (provider -> profile/mode -> suffix)"
      echo "  -s, --simple: flat prefix picker mode"
    }

    supports_workflow_suffix() {
      case "$1" in
        cl|clu|clglm|ocl|hcl|cx|cxu|lcx|mcx|hcx|xcx|oc|ocglm|ocgem|ocgpt|locgpt|mocgpt|hocgpt|xocgpt|ocs|oczen)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
    }

    resolve_workflow_prompt() {
      case "$1" in
        cm)
          echo ${lib.escapeShellArg commitSplitPrompt}
          ;;
        rf)
          echo ${lib.escapeShellArg refactorMaintainabilityPrompt}
          ;;
        sa)
          echo ${lib.escapeShellArg securityAuditPrompt}
          ;;
        bp)
          echo ${lib.escapeShellArg buildPerformancePrompt}
          ;;
        md)
          echo ${lib.escapeShellArg markdownSyncPrompt}
          ;;
        *)
          return 1
          ;;
      esac
    }

    choose_workflow_suffix() {
      local base_alias="$1"
      local suffix

      if ! supports_workflow_suffix "$base_alias"; then
        echo "none"
        return 0
      fi

      suffix="$(pick "Select Workflow Suffix" none cm rf sa bp md)"
      if [ -z "''${suffix:-}" ]; then
        return 1
      fi

      echo "$suffix"
    }

    execute_claude_glm() {
      local prompt="''${1:-}"
      local key_file key

      key_file="/run/secrets/zai_api_key"
      if [ ! -f "$key_file" ]; then
        echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
        exit 1
      fi

      key="$(cat "$key_file")"
      if [ -z "$prompt" ]; then
        exec env \
          ANTHROPIC_AUTH_TOKEN="$key" \
          ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
          API_TIMEOUT_MS="3000000" \
          ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
          ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5" \
          ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5" \
          claude --dangerously-skip-permissions
      else
        exec env \
          ANTHROPIC_AUTH_TOKEN="$key" \
          ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
          API_TIMEOUT_MS="3000000" \
          ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
          ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5" \
          ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5" \
          claude --dangerously-skip-permissions "$prompt"
      fi
    }

    execute_agent() {
      local agent_alias="$1"
      local workflow_suffix="$2"
      local prompt=""

      if [ "$workflow_suffix" != "none" ]; then
        prompt="$(resolve_workflow_prompt "$workflow_suffix")"
      fi

      case "$agent_alias" in
        cl|clu)
          if [ -z "$prompt" ]; then
            exec claude --dangerously-skip-permissions
          else
            exec claude --dangerously-skip-permissions "$prompt"
          fi
          ;;
        ocl)
          if [ -z "$prompt" ]; then
            exec claude --dangerously-skip-permissions --model opus
          else
            exec claude --dangerously-skip-permissions --model opus "$prompt"
          fi
          ;;
        hcl)
          if [ -z "$prompt" ]; then
            exec claude --dangerously-skip-permissions --model haiku
          else
            exec claude --dangerously-skip-permissions --model haiku "$prompt"
          fi
          ;;
        clglm)
          execute_claude_glm "$prompt"
          ;;
        gem)
          exec gemini --yolo
          ;;
        cx|cxu)
          if [ -z "$prompt" ]; then
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox
          else
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox "$prompt"
          fi
          ;;
        lcx)
          if [ -z "$prompt" ]; then
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"low\""
          else
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"low\"" "$prompt"
          fi
          ;;
        mcx)
          if [ -z "$prompt" ]; then
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"medium\""
          else
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"medium\"" "$prompt"
          fi
          ;;
        hcx)
          if [ -z "$prompt" ]; then
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"high\""
          else
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"high\"" "$prompt"
          fi
          ;;
        xcx)
          if [ -z "$prompt" ]; then
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"xhigh\""
          else
            exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c "model_reasoning_effort=\"xhigh\"" "$prompt"
          fi
          ;;
        oc)
          if [ -z "$prompt" ]; then
            exec opencode
          else
            exec opencode --prompt "$prompt"
          fi
          ;;
        ocglm)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" opencode
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" opencode --prompt "$prompt"
          fi
          ;;
        ocgem)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gemini" opencode
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gemini" opencode --prompt "$prompt"
          fi
          ;;
        ocgpt)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --prompt "$prompt"
          fi
          ;;
        locgpt)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex-spark
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex-spark --prompt "$prompt"
          fi
          ;;
        mocgpt)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex --prompt "$prompt"
          fi
          ;;
        hocgpt)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.4
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.4 --prompt "$prompt"
          fi
          ;;
        xocgpt)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.1-codex-max
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.1-codex-max --prompt "$prompt"
          fi
          ;;
        ocs)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-sonnet" opencode
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-sonnet" opencode --prompt "$prompt"
          fi
          ;;
        oczen)
          if [ -z "$prompt" ]; then
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-zen" opencode
          else
            exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-zen" opencode --prompt "$prompt"
          fi
          ;;
        *)
          echo "Unsupported alias: $agent_alias" >&2
          exit 1
          ;;
      esac
    }

    pick_codex_effort_alias() {
      local effort
      effort="$(pick "Codex Reasoning Effort" default low medium high xhigh)"
      case "$effort" in
        default) echo "cx" ;;
        low) echo "lcx" ;;
        medium) echo "mcx" ;;
        high) echo "hcx" ;;
        xhigh) echo "xcx" ;;
        "") return 1 ;;
      esac
    }

    pick_ocgpt_effort_alias() {
      local effort
      effort="$(pick "OpenCode GPT Reasoning Effort" default low medium high xhigh)"
      case "$effort" in
        default) echo "ocgpt" ;;
        low) echo "locgpt" ;;
        medium) echo "mocgpt" ;;
        high) echo "hocgpt" ;;
        xhigh) echo "xocgpt" ;;
        "") return 1 ;;
      esac
    }

    run_simple_mode() {
      local agent_alias claude_mode

      agent_alias="$(pick "Simple Mode: Select Agent Prefix" \
        cl ocl hcl clglm \
        oc ocglm ocgem ocgpt locgpt mocgpt hocgpt xocgpt ocs oczen \
        cx lcx mcx hcx xcx cxu \
        gem)"
      if [ -z "''${agent_alias:-}" ]; then
        return 1
      fi

      if [ "$agent_alias" = "cl" ]; then
        claude_mode="$(pick "Claude Model" default opus haiku)"
        case "$claude_mode" in
          default) agent_alias="cl" ;;
          opus) agent_alias="ocl" ;;
          haiku) agent_alias="hcl" ;;
          "") return 1 ;;
        esac
      fi

      case "$agent_alias" in
        cx|lcx|mcx|hcx|xcx)
          agent_alias="$(pick_codex_effort_alias)" || return 1
          ;;
      esac

      case "$agent_alias" in
        ocgpt|locgpt|mocgpt|hocgpt|xocgpt)
          agent_alias="$(pick_ocgpt_effort_alias)" || return 1
          ;;
      esac

      echo "$agent_alias"
    }

    run_sectioned_mode() {
      local provider_choice profile_choice mode_choice agent_alias

      provider_choice="$(pick "Select Provider" "OpenCode" "Claude Code" "Codex" "Gemini")"
      if [ -z "''${provider_choice:-}" ]; then
        return 1
      fi

      case "$provider_choice" in
        "OpenCode")
          profile_choice="$(pick "OpenCode Profile" default glm gemini gpt sonnet zen)"
          case "$profile_choice" in
            default) agent_alias="oc" ;;
            glm) agent_alias="ocglm" ;;
            gemini) agent_alias="ocgem" ;;
            gpt) agent_alias="$(pick_ocgpt_effort_alias)" || return 1 ;;
            sonnet) agent_alias="ocs" ;;
            zen) agent_alias="oczen" ;;
            "") return 1 ;;
          esac
          ;;
        "Claude Code")
          mode_choice="$(pick "Claude Mode" default opus haiku glm)"
          case "$mode_choice" in
            default) agent_alias="cl" ;;
            opus) agent_alias="ocl" ;;
            haiku) agent_alias="hcl" ;;
            glm) agent_alias="clglm" ;;
            "") return 1 ;;
          esac
          ;;
        "Codex")
          agent_alias="$(pick_codex_effort_alias)" || return 1
          ;;
        "Gemini")
          agent_alias="gem"
          ;;
      esac

      echo "$agent_alias"
    }

    simple_mode=false
    while [ $# -gt 0 ]; do
      case "$1" in
        -s|--simple)
          simple_mode=true
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown argument: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
      shift
    done

    agent_alias=""
    workflow_suffix=""

    if [ "$simple_mode" = true ]; then
      agent_alias="$(run_simple_mode)" || exit 0
    else
      agent_alias="$(run_sectioned_mode)" || exit 0
    fi

    workflow_suffix="$(choose_workflow_suffix "$agent_alias")" || exit 0

    execute_agent "$agent_alias" "$workflow_suffix"
  '';
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
              "ais" = "ai-agent-launcher";
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
        aiAgentLauncher
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
