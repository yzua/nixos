# Model selections, provider registries, and per-agent tool configurations (OpenCode, Codex, Gemini).

{
  config,
  constants,
  ...
}:

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
  workflowPrompts = import ../helpers/_workflow-prompts.nix;
  mkAllowPatterns =
    patterns:
    builtins.listToAttrs (
      map (pattern: {
        name = pattern;
        value = "allow";
      }) patterns
    );
  readOnlyBashPatterns = mkAllowPatterns [
    "pwd"
    "pwd *"
    "ls"
    "ls *"
    "find *"
    "rg"
    "rg *"
    "grep *"
    "sed *"
    "cat *"
    "head *"
    "tail *"
    "wc *"
    "stat *"
    "tree *"
    "file *"
    "strings *"
    "jq *"
    "git status*"
    "git diff*"
    "git log*"
    "git show*"
    "git branch*"
    "git ls-files*"
  ];
  yoloPermission = "allow";
  planningPermission = {
    read = "allow";
    edit = "deny";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = readOnlyBashPatterns;
    task = "allow";
    todowrite = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    codesearch = "allow";
    lsp = "allow";
    external_directory = "deny";
    doom_loop = "deny";
    skill = "allow";
  };
  reviewPermission = {
    read = "allow";
    edit = "deny";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = readOnlyBashPatterns;
    task = "allow";
    todowrite = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    codesearch = "allow";
    lsp = "allow";
    external_directory = "deny";
    doom_loop = "deny";
    skill = "allow";
  };
in
{
  programs.aiAgents = {
    agencyAgents.enable = false;
    impeccable.enable = true;

    # === OpenCode Configuration ===
    opencode = {
      enable = true;
      model = "anthropic/claude-opus-4-6";
      defaultAgent = "build";
      permission = yoloPermission;

      plugins = [
        "opencode-antigravity-auth@latest"
      ];

      command = {
        "commit-split" = {
          description = "Split current changes into minimal logical signed commits";
          agent = "patch";
          subtask = true;
          template = workflowPrompts.commitSplit;
        };
        refactor = {
          description = "Raise maintainability without behavior drift";
          agent = "patch";
          subtask = true;
          template = workflowPrompts.refactorMaintainability;
        };
        "security-audit" = {
          description = "Run an evidence-first security review";
          agent = "review";
          subtask = true;
          template = workflowPrompts.securityAudit;
        };
        "build-perf" = {
          description = "Measure and improve build bottlenecks";
          agent = "build";
          subtask = true;
          template = workflowPrompts.buildPerformance;
        };
        "markdown-sync" = {
          description = "Sync docs with current repository behavior";
          agent = "patch";
          subtask = true;
          template = workflowPrompts.markdownSync;
        };
      };

      agent = {
        plan = {
          model = "anthropic/claude-sonnet-4-6";
          description = "Primary planning agent for specs, decomposition, and research-backed execution plans.";
          mode = "primary";
          steps = 8;
          permission = planningPermission;
          prompt = ''
            Produce implementation plans that are decision-complete before execution starts.
            Clarify goal, constraints, validation path, interfaces, and rollout risks.
            Prefer evidence from repository files, generated config, and current tool output over assumptions.
          '';
        };
        build = {
          model = "anthropic/claude-opus-4-6";
          description = "Primary implementation agent for coding work with repo-native validation.";
          mode = "primary";
          steps = 20;
          permission = yoloPermission;
          prompt = ''
            Implement minimal, high-leverage changes that match repository conventions.
            Reuse local patterns, validate with narrow checks first, and avoid speculative refactors.
            Treat formatter, lint, eval, and build output as required evidence before claiming success.
          '';
        };
        review = {
          model = "anthropic/claude-sonnet-4-6";
          description = "Subagent for bugs, regressions, security issues, and test gaps.";
          mode = "subagent";
          color = "warning";
          steps = 12;
          permission = reviewPermission;
          prompt = ''
            Review code and configuration changes for correctness first.
            Prioritize concrete bugs, behavioral regressions, security issues, and missing validation.
            Do not edit files. Report exact evidence with file and line references when available.
          '';
        };
        recon = {
          model = "openai/gpt-5.4";
          description = "Subagent for reverse-engineering triage, static inspection, and evidence gathering.";
          mode = "subagent";
          color = "info";
          steps = 16;
          permission = yoloPermission;
          prompt = ''
            Focus on reverse-engineering and static triage.
            Map binaries, strings, symbols, endpoints, protocols, config formats, persistence, and trust boundaries.
            Prefer non-mutating inspection and summarize likely next probes before suggesting dynamic work.
          '';
        };
        patch = {
          model = "anthropic/claude-sonnet-4-6";
          description = "Subagent for bounded edits, validation passes, and commit shaping.";
          mode = "subagent";
          color = "accent";
          steps = 10;
          permission = yoloPermission;
          prompt = ''
            Make tightly scoped edits against an existing plan or clearly bounded task.
            Preserve behavior unless the task explicitly changes behavior.
            After edits, run the narrowest relevant validation and summarize residual risk.
          '';
        };
      };

      lsp = {
        bash = {
          command = [
            "bash-language-server"
            "start"
          ];
          extensions = [
            "sh"
            "bash"
            "zsh"
          ];
        };
        go = {
          command = [ "gopls" ];
          extensions = [ "go" ];
        };
        nix = {
          command = [ "nixd" ];
          extensions = [ "nix" ];
        };
        python = {
          command = [
            "pyright-langserver"
            "--stdio"
          ];
          extensions = [
            "py"
            "pyi"
          ];
        };
        typescript = {
          command = [
            "typescript-language-server"
            "--stdio"
          ];
          extensions = [
            "js"
            "jsx"
            "ts"
            "tsx"
            "mjs"
            "cjs"
          ];
        };
        json = {
          command = [
            "vscode-json-language-server"
            "--stdio"
          ];
          extensions = [
            "json"
            "jsonc"
          ];
        };
        yaml = {
          command = [
            "yaml-language-server"
            "--stdio"
          ];
          extensions = [
            "yaml"
            "yml"
          ];
        };
        clang = {
          command = [ "clangd" ];
          extensions = [
            "c"
            "cc"
            "cpp"
            "cxx"
            "h"
            "hpp"
          ];
        };
        rust = {
          command = [ "rust-analyzer" ];
          extensions = [ "rs" ];
        };
      };

      experimental = {
        batch_tool = true;
        continue_loop_on_deny = true;
        mcp_timeout = 120000;
        openTelemetry = config.programs.aiAgents.logging.enableOtel;
      };

      extraSettings = {
        share = "disabled";
        autoupdate = true;
        small_model = "anthropic/claude-haiku-4-5"; # Cheap model for titles, summaries
        compaction = {
          auto = true;
          prune = true; # Remove old tool outputs during compaction
          reserved = 10000; # Reserved tokens after compaction
        };
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
      sandboxMode = "workspace-write";
      enableSearch = false;
      personality = "pragmatic";
      reasoningEffort = "medium";
      approvalPolicy = "on-request";
      features = {
        apps = false;
        child_agents_md = true;
        multi_agent = true;
        plugins = true;
        shell_snapshot = true;
        tool_suggest = true;
        unified_exec = true;
      };
      trustedProjects = [
        "${config.home.homeDirectory}/System"
      ];
      profiles = {
        quick = {
          reasoningEffort = "low";
        };
        deep = {
          reasoningEffort = "xhigh";
          approvalPolicy = "on-request";
          sandboxMode = "workspace-write";
        };
        safe = {
          approvalPolicy = "untrusted";
          sandboxMode = "read-only";
        };
        review = {
          personality = "pragmatic";
          reasoningEffort = "high";
          approvalPolicy = "on-request";
          developerInstructions = ''
            Run in review mode. Prioritize bugs, regressions, security issues, and missing tests.
            Findings come first with exact file and line references when available.
          '';
        };
      };
      customAgents = {
        reviewer = {
          description = "Review-focused agent for bugs, regressions, security issues, and missing tests.";
          reasoningEffort = "high";
          approvalPolicy = "on-request";
          sandboxMode = "read-only";
          developerInstructions = ''
            Perform code review only. Do not implement changes.
            Prioritize correctness, behavior drift, security issues, and test gaps.
            Findings must be concise, ordered by severity, and include exact evidence.
          '';
        };
        recon = {
          description = "Read-heavy reverse-engineering triage agent for static inspection and evidence gathering.";
          reasoningEffort = "high";
          approvalPolicy = "on-request";
          sandboxMode = "read-only";
          enableSearch = true;
          developerInstructions = ''
            Focus on static triage and evidence gathering.
            Map strings, imports, symbols, embedded endpoints, protocols, config formats, and trust boundaries.
            Do not mutate files or run samples unless explicitly asked.
          '';
        };
      };
      extraToml = ''
        [agents]
        max_threads = 4

        [agents.explorer]
        description = "Read-only style codebase exploration, file tracing, and evidence gathering."

        [agents.worker]
        description = "Targeted implementation and fixes after the task is understood."

        [agents.monitor]
        description = "Long-running command, build, and polling monitor with concise status updates."
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
                    (import ./_formatters.nix).geminiCaseBranches
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
