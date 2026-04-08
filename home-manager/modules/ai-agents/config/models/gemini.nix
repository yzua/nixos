# Gemini CLI configuration: settings, theming, model aliases, and auto-format hooks.

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
in
{
  programs.aiAgents.gemini = {
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
                  (import ../_formatters.nix).geminiCaseBranches
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
