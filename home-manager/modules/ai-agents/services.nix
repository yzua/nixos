# Zsh aliases, systemd user services/timers, and packages for AI agents.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      AI_AGENT_NOTIFY_ON_ERROR=${if cfg.logging.notifyOnError then "true" else "false"} \
      exec ${config.home.homeDirectory}/System/scripts/ai/agent-log-wrapper.sh "$@"
  '';
  androidReLaunchers =
    let
      launcherScript = "${config.home.homeDirectory}/System/scripts/ai/android-re/opencode-android-re.sh";
      promptSourceDir = "${config.home.homeDirectory}/System/home-manager/modules/ai-agents/android-re/prompts";
      mkAndroidReLauncher =
        {
          name,
          profile,
        }:
        pkgs.writeShellScriptBin name ''
          ANDROID_RE_PROMPT_SOURCE_DIR=${lib.escapeShellArg promptSourceDir} \
            ANDROID_RE_OPENCODE_PROFILE=${lib.escapeShellArg profile} \
            exec ${launcherScript} "$@"
        '';
    in
    map mkAndroidReLauncher [
      {
        name = "ocare";
        profile = "default";
      }
      {
        name = "ocglmare";
        profile = "glm";
      }
      {
        name = "ocgemare";
        profile = "gemini";
      }
      {
        name = "ocgptare";
        profile = "gpt";
      }
      {
        name = "ocorare";
        profile = "openrouter";
      }
      {
        name = "ocsare";
        profile = "sonnet";
      }
      {
        name = "oczenare";
        profile = "zen";
      }
    ];

  aliasLib = import ./helpers/_aliases.nix { inherit config lib pkgs; };
  inherit (aliasLib) aiAliases aiAgentLauncher aiAgentInventory;

  logCleanupCommand = ''
    find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
    find "$HOME/.local/share/opencode/log" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
    find "$HOME/.codex/log" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
  '';

  mkWeeklyTimer = description: {
    Unit.Description = description;
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  mkCliAutoupdateScript =
    {
      binary,
      npmPackage,
      label,
    }:
    pkgs.writeShellScript "${binary}-autoupdate" ''
      if ! command -v ${binary} >/dev/null 2>&1; then
        exit 0
      fi

      binary_path="$(readlink -f "$(command -v ${binary})")"

      if [[ "$binary_path" == *"/.bun/install/global/"* ]]; then
        ${pkgs.bun}/bin/bun install -g ${npmPackage}@latest
      elif [[ "$binary_path" == *"/.npm-global/"* ]]; then
        ${pkgs.nodejs}/bin/npm install -g ${npmPackage}@latest
      elif command -v bun >/dev/null 2>&1; then
        bun install -g ${npmPackage}@latest
      elif command -v npm >/dev/null 2>&1; then
        npm install -g ${npmPackage}@latest
      else
        echo "No supported package manager found for ${label} auto-update"
        exit 1
      fi

      echo "Updated ${label}"
    '';
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
              "ait" = "ai-agent-inventory";
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
        aiAgentInventory
        pkgs.bubblewrap
      ]
      ++ androidReLaunchers
      ++ (lib.optional cfg.logging.enable (
        pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
          ${logCleanupCommand}
          echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
        ''
      ));

      home.sessionVariables = lib.mkIf cfg.opencode.enable {
        OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
      };

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
      };
    }
  );
}
