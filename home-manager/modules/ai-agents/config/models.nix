# Model selections, provider registries, and per-agent tool configurations (OpenCode, Codex, Gemini).

{ config, constants, ... }:

let
  mkModelAlias = model: generateContentConfig: {
    modelConfig = {
      inherit model generateContentConfig;
    };
  };
  mkThinkingAlias =
    model: thinkingLevel: extraConfig:
    mkModelAlias model (
      {
        thinkingConfig = {
          inherit thinkingLevel;
        };
      }
      // extraConfig
    );
in
{
  programs.aiAgents = {
    agencyAgents.enable = true;
    impeccable.enable = true;

    # === OpenCode Configuration ===
    opencode = {
      enable = true;
      model = "anthropic/claude-opus-4-6";

      plugins = [
        "opencode-antigravity-auth@latest"
      ];

      ohMyOpencode.enable = false;

      extraSettings = {
        share = "disabled";
        autoupdate = true;
        small_model = "anthropic/claude-haiku-4-5"; # Cheap model for titles, summaries
        compaction = {
          auto = true;
          prune = true; # Remove old tool outputs during compaction
          reserved = 10000; # Reserved tokens after compaction
        };
        # Custom slash commands are disabled by default.
        # To add one, uncomment and adapt this block:
        # command = {
        #   mycmd = {
        #     template = "Describe what /mycmd should do.";
        #     description = "Short help text shown in command list";
        #     agent = "build";
        #     subtask = true;
        #   };
        # };
      };

      providers = {
        google = {
          npm = "@ai-sdk/google";
          models = {
            "antigravity-gemini-3.1-pro" = {
              name = "Gemini 3.1 Pro (Antigravity)";
              limit = {
                context = 1048576;
                output = 65535;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                low = {
                  thinkingLevel = "low";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
            "antigravity-gemini-3-flash" = {
              name = "Gemini 3 Flash (Antigravity)";
              limit = {
                context = 1048576;
                output = 65536;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
              variants = {
                minimal = {
                  thinkingLevel = "minimal";
                };
                low = {
                  thinkingLevel = "low";
                };
                medium = {
                  thinkingLevel = "medium";
                };
                high = {
                  thinkingLevel = "high";
                };
              };
            };
          };
        };
        openrouter = {
          options = {
            apiKey = "__OPENROUTER_API_KEY_PLACEHOLDER__";
          };
        };
      };
    };

    # === Codex Configuration ===
    codex = {
      enable = true;
      useWrapper = true;
      model = "gpt-5.4";
      personality = "pragmatic";
      reasoningEffort = "medium";
      approvalPolicy = "on-request";
      trustedProjects = [
        "${config.home.homeDirectory}/System"
      ];
      extraToml = ''
        [agents]
        max_threads = 4

        [agents.explorer]
        description = "Read-only style codebase exploration, file tracing, and evidence gathering."

        [agents.worker]
        description = "Targeted implementation and fixes after the task is understood."

        [agents.monitor]
        description = "Long-running command, build, and polling monitor with concise status updates."

        [features]
        multi_agent = true
        child_agents_md = true

        [profiles.nix]
        model_reasoning_effort = "high"
        approval_policy = "on-request"
        developer_instructions = """
        You are working on a NixOS flake-based configuration.
        Use 'just modules' to validate imports, 'just lint' for linting,
        'just format' for formatting, 'just check' for flake evaluation.
        Follow patterns in nearby modules. Use lib.mkIf for conditionals.
        Custom options live under mySystem.* namespace.
        """

        [profiles.review]
        personality = "pragmatic"
        model_reasoning_effort = "high"
        approval_policy = "on-request"
      '';
    };

    # === Gemini Configuration ===
    gemini = {
      enable = true;
      theme = "Gruvbox";
      sandboxMode = "cautious";

      extraSettings = {
        # --- Core Features ---
        codeExecution = true;
        searchGrounding = true;
        # --- Security ---
        security = {
          auth = {
            selectedType = "gemini-api-key";
          };
          folderTrust = {
            enabled = true;
          };
        };
        # --- MCP Server Access ---
        mcp = {
          allowed = [
            "context7"
            "github"
            "web-search-prime"
            "web-reader"
            "zread"
          ];
          excluded = [
          ];
        };
        # --- Context Settings ---
        context = {
          fileName = [
            "GEMINI.md"
            "AGENTS.md"
          ];
          importFormat = "markdown";
          fileFiltering = {
            respectGitIgnore = true;
            respectGeminiIgnore = true;
            enableRecursiveFileSearch = true;
          };
        };
        # --- General Settings ---
        general = {
          vimMode = true;
          enableAutoUpdate = true;
          enableAutoUpdateNotification = true;
          checkpointing.enabled = false; # NixOS: simple-git .env() strips PATH → git ENOENT (upstream bug)
          sessionRetention = {
            enabled = true;
            maxAge = "30d";
          };
        };
        # --- Privacy ---
        privacy = {
          usageStatisticsEnabled = false;
        };
        # --- UI and Theming ---
        ui = {
          hideTips = true;
          hideBanner = true;
          showLineNumbers = true;
          customThemes = {
            Gruvbox = {
              name = "Gruvbox";
              type = "custom";
              Background = constants.color.bg_soft;
              Foreground = constants.color.fg0;
              LightBlue = constants.color.blue;
              AccentBlue = constants.color.blue_dim;
              AccentPurple = constants.color.purple_dim;
              AccentCyan = constants.color.aqua;
              AccentGreen = constants.color.green;
              AccentYellow = constants.color.yellow;
              AccentRed = constants.color.red;
              Comment = constants.color.gray;
              Gray = constants.color.gray_dim;
              DiffAdded = constants.color.green;
              DiffRemoved = constants.color.red;
            };
          };
          theme = "Gruvbox";
        };
        # --- Experimental Features ---
        experimental = {
          enableAgents = true;
        };
        # --- Model Aliases ---
        modelConfigs = {
          customAliases = {
            fast = mkModelAlias "gemini-2.5-flash-lite" {
              temperature = 0;
              maxOutputTokens = 8192;
            };
            deep = mkThinkingAlias "gemini-3-pro-preview" "HIGH" { };
            code = mkThinkingAlias "gemini-2.5-pro" "HIGH" {
              maxOutputTokens = 65536;
            };
          };
        };
        # --- Tool Settings ---
        tools = {
          approvalMode = "auto_edit";
        };
        # --- Model Compression ---
        model = {
          compressionThreshold = 0.75; # Wait until 75% full before compressing (was 0.5)
        };
        # --- Hooks ---
        hooks = {
          AfterTool = [
            {
              matcher = "write_file|replace";
              hooks = [
                {
                  name = "auto-format";
                  type = "command";
                  command = builtins.concatStringsSep " " [
                    "INPUT=$(cat);"
                    "FILE_PATH=$(echo \"$INPUT\" | jq -r '.arguments.path // \"\"');"
                    "if [ -n \"$FILE_PATH\" ]; then"
                    "case \"$FILE_PATH\" in"
                    "*.nix) command -v nixfmt >/dev/null 2>&1 && nixfmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.jsonc|*.css|*.scss|*.less|*.graphql|*.gql) command -v biome >/dev/null 2>&1 && biome check --write \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.rs) command -v rustfmt >/dev/null 2>&1 && rustfmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.go) command -v gofmt >/dev/null 2>&1 && gofmt -w \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.py|*.pyi) command -v ruff >/dev/null 2>&1 && ruff format \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.zig|*.zon) command -v zig >/dev/null 2>&1 && zig fmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.md|*.mdx|*.yaml|*.yml|*.html|*.vue|*.svelte|*.astro) command -v prettier >/dev/null 2>&1 && prettier --write \"$FILE_PATH\" 2>/dev/null ;;"
                    "esac;"
                    "fi;"
                    "echo \"$INPUT\""
                  ];
                  timeout = 10000;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
