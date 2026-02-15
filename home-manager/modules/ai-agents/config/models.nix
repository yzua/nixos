# Model selections, provider registries, and per-agent tool configurations (OpenCode, Codex, Gemini).
{ config, constants, ... }:

{
  programs.aiAgents = {
    opencode = {
      enable = true;
      model = "anthropic/claude-opus-4-6";

      plugins = [
        "oh-my-opencode"
        "opencode-antigravity-auth"
        "opencode-anthropic-auth"
      ];

      extraSettings = {
        tui = {
          theme = "gruvbox";
          show_tokens = true;
          show_cost = true;
        };
        small_model = "anthropic/claude-haiku-4-5"; # Cheap model for titles, summaries
        compaction = {
          auto = true;
          prune = true; # Remove old tool outputs during compaction
          reserved = 10000; # Reserved tokens after compaction
        };
        command = {
          test = {
            template = "Run the project test suite. If a justfile exists, use 'just check'. Otherwise find and run the appropriate test command.";
            description = "Run project tests";
          };
          deploy = {
            template = "Run the NixOS deployment pipeline: just modules && just lint && just format && just check && just home. Only run 'just nixos' if I explicitly confirm.";
            description = "Deploy NixOS configuration";
          };
          review = {
            template = "Review the staged git changes (git diff --staged). Check for: correctness, edge cases, security issues, performance problems, maintainability. Rate issues as CRITICAL/WARNING/SUGGESTION.";
            description = "Review staged changes";
          };
        };
      };

      providers = {
        google = {
          models = {
            "antigravity-gemini-3-pro" = {
              name = "Gemini 3 Pro (Antigravity)";
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
            "antigravity-claude-sonnet-4-5" = {
              name = "Claude Sonnet 4.5 (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
              };
              modalities = {
                input = [
                  "text"
                  "image"
                  "pdf"
                ];
                output = [ "text" ];
              };
            };
            "antigravity-claude-opus-4-6-thinking" = {
              name = "Claude Opus 4.6 Thinking (Antigravity)";
              limit = {
                context = 200000;
                output = 64000;
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
                  thinkingConfig = {
                    thinkingBudget = 8192;
                  };
                };
                max = {
                  thinkingConfig = {
                    thinkingBudget = 32768;
                  };
                };
              };
            };
          };
        };
      };
    };

    codex = {
      enable = true;
      useWrapper = true;
      model = "gpt-5.3-codex";
      personality = "pragmatic";
      reasoningEffort = "medium";
      approvalPolicy = "on-request";
      trustedProjects = [
        "${config.home.homeDirectory}/System"
      ];
      extraToml = ''
        [features]
        request_rule = true
        collaboration_modes = true
        personality = true
        model_reasoning_summary = true
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

    gemini = {
      enable = true;
      theme = "Gruvbox";
      sandboxMode = "cautious";

      extraSettings = {
        codeExecution = true;
        searchGrounding = true;
        security = {
          folderTrust = {
            enabled = true;
          };
        };
        mcp = {
          allowed = [
            "context7"
            "zai-mcp-server"
            "filesystem"
            "memory"
            "sequential-thinking"
            "playwright"
            "cloudflare-docs"
            "github"
          ];
          excluded = [
            "git"
            "web-search-prime"
            "cloudflare-workers-builds"
            "cloudflare-workers-bindings"
            "cloudflare-observability"
          ];
        };
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
        general = {
          vimMode = true;
          enableAutoUpdate = true;
          enableAutoUpdateNotification = true;
          checkpointing.enabled = true;
          sessionRetention = {
            enabled = true;
            maxAge = "30d";
          };
        };
        privacy = {
          usageStatisticsEnabled = false;
        };
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
        experimental = {
          enableAgents = true;
        };
        modelConfigs = {
          customAliases = {
            fast = {
              modelConfig = {
                model = "gemini-2.5-flash-lite";
                generateContentConfig = {
                  temperature = 0;
                  maxOutputTokens = 8192;
                };
              };
            };
            deep = {
              modelConfig = {
                model = "gemini-3-pro-preview";
                generateContentConfig = {
                  thinkingConfig = {
                    thinkingLevel = "HIGH";
                  };
                };
              };
            };
            code = {
              modelConfig = {
                model = "gemini-2.5-pro";
                generateContentConfig = {
                  thinkingConfig = {
                    thinkingLevel = "HIGH";
                  };
                  maxOutputTokens = 65536;
                };
              };
            };
          };
        };
        tools = {
          approvalMode = "auto_edit";
        };
        model = {
          compressionThreshold = 0.75; # Wait until 75% full before compressing (was 0.5)
        };
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
                    "*.ts|*.tsx|*.js|*.jsx|*.json) command -v biome >/dev/null 2>&1 && biome check --write \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.rs) command -v rustfmt >/dev/null 2>&1 && rustfmt \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.go) command -v gofmt >/dev/null 2>&1 && gofmt -w \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.py) command -v ruff >/dev/null 2>&1 && ruff format \"$FILE_PATH\" 2>/dev/null ;;"
                    "*.zig) command -v zig >/dev/null 2>&1 && zig fmt \"$FILE_PATH\" 2>/dev/null ;;"
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
