# Gemini CLI configuration: settings, theming, model aliases, and auto-format hooks.

{
  config,
  constants,
  ...
}:

let
  models = import ../../helpers/_models.nix;

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
  programs.aiAgents.gemini = {
    enable = true;
    theme = "Gruvbox";
    sandboxMode = "none";

    extraSettings = {
      policyPaths = [ "$HOME/.gemini/policies" ];
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
          "chrome-devtools"
          "web-search-prime"
          "web-reader"
          "zread"
        ];
      };
      # --- Context Settings ---
      context = {
        fileName = [
          "GEMINI.md"
          "AGENTS.md"
        ];
        importFormat = "markdown";
        discoveryMaxDirs = 300;
        loadMemoryFromIncludeDirectories = true;
        fileFiltering = {
          respectGitIgnore = true;
          respectGeminiIgnore = true;
          enableRecursiveFileSearch = true;
          enableFuzzySearch = true;
        };
      };
      # --- General Settings ---
      general = {
        vimMode = true;
        defaultApprovalMode = "auto_edit";
        enableAutoUpdate = true;
        enableAutoUpdateNotification = true;
        checkpointing.enabled = false; # NixOS: simple-git .env() strips PATH → git ENOENT (upstream bug)
        plan.modelRouting = true;
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
            background = {
              primary = constants.color.bg_soft;
              diff = {
                added = constants.color.bg0;
                removed = constants.color.bg1;
              };
            };
            text = {
              primary = constants.color.fg0;
              secondary = constants.color.gray;
              link = constants.color.blue;
              accent = constants.color.purple_dim;
            };
            border = {
              default = constants.color.fg_dark;
              focused = constants.color.blue;
            };
            status = {
              success = constants.color.green;
              warning = constants.color.yellow;
              error = constants.color.red;
            };
            ui = {
              comment = constants.color.gray;
              symbol = constants.color.aqua;
              gradient = [
                constants.color.red
                constants.color.orange
                constants.color.yellow
              ];
            };
          };
        };
        inherit (config.programs.aiAgents.gemini) theme;
      };
      # --- Experimental Features ---
      experimental = {
        enableAgents = true;
        worktrees = true;
      };
      skills.enabled = true;
      agents = {
        overrides = {
          codebase_investigator = {
            enabled = true;
            modelConfig.model = models.gemini-pro;
            runConfig.maxTurns = 50;
          };
        };
      };
      # --- Model Aliases ---
      modelConfigs = {
        customAliases = {
          auto = mkModelAlias "auto" { };
          fast = mkModelAlias models.gemini-flash-lite {
            temperature = 0;
            maxOutputTokens = 8192;
          };
          flash = mkModelAlias models.gemini-flash {
            temperature = 0;
            maxOutputTokens = 16384;
          };
          deep = mkThinkingAlias models.gemini-pro "HIGH" { };
          code = mkThinkingAlias models.gemini-pro "HIGH" {
            maxOutputTokens = 65536;
          };
        };
      };
      # --- Tool Settings ---
      tools = {
        sandbox = false;
        sandboxNetworkAccess = false;
        shell.showColor = true;
        useRipgrep = true;
      };
      # --- Model Defaults And Compression ---
      model = {
        name = models.gemini-pro;
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
                  (import ../../helpers/_formatters.nix).geminiCaseBranches
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
}
