# Home file and XDG config file declarations for AI agents.

{
  config,
  constants,
  lib,
  ...
}:

let
  cfg = config.programs.aiAgents;

  inherit (builtins) toJSON;

  fileTemplates = import ./helpers/_file-templates.nix;
  geminiPolicies = import ./helpers/_gemini-policies.nix;
  impeccable = import ./helpers/_impeccable-commands.nix;
  models = import ./helpers/_models.nix;
  agentEnvContent = import ./helpers/_agent-env.nix { inherit constants; };
  settingsBuilders = import ./helpers/_settings-builders.nix { inherit cfg config lib; };
  inherit (settingsBuilders)
    geminiSettings
    opencodeSettingsByProfile
    ;

  opencodeProfiles = import ./helpers/_opencode-profiles.nix { inherit config; };
  opencodeProfileNames = opencodeProfiles.names;
  opencodeGruvboxDarkTheme = toJSON {
    "$schema" = "https://opencode.ai/theme.json";
    defs = {
      bg0 = "#282828";
      bg1 = "#32302f";
      bg2 = "#3c3836";
      bg3 = "#504945";
      bg4 = "#665c54";
      fg0 = "#ebdbb2";
      fg2 = "#a89984";
      yellow = "#fabd2f";
      blue = "#83a598";
      purple = "#d3869b";
      red = "#fb4934";
      green = "#b8bb26";
      aqua = "#8ec07c";
      orange = "#fe8019";
    };
    theme = {
      primary = {
        dark = "yellow";
        light = "yellow";
      };
      secondary = {
        dark = "blue";
        light = "blue";
      };
      accent = {
        dark = "purple";
        light = "purple";
      };
      error = {
        dark = "red";
        light = "red";
      };
      warning = {
        dark = "orange";
        light = "orange";
      };
      success = {
        dark = "green";
        light = "green";
      };
      info = {
        dark = "aqua";
        light = "aqua";
      };
      text = {
        dark = "fg0";
        light = "fg0";
      };
      textMuted = {
        dark = "fg2";
        light = "fg2";
      };
      background = {
        dark = "bg0";
        light = "bg0";
      };
      backgroundPanel = {
        dark = "bg1";
        light = "bg1";
      };
      backgroundElement = {
        dark = "bg2";
        light = "bg2";
      };
      border = {
        dark = "bg3";
        light = "bg3";
      };
      borderActive = {
        dark = "bg4";
        light = "bg4";
      };
      borderSubtle = {
        dark = "bg2";
        light = "bg2";
      };
    };
  };

  opencodeConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (name: [
        {
          name = "${name}/opencode.json";
          value = {
            text = toJSON opencodeSettingsByProfile.${name};
            force = true;
          };
        }
        {
          name = "${name}/tui.json";
          value = {
            text = toJSON {
              theme = "gruvbox-dark";
            };
            force = true;
          };
        }
        {
          name = "${name}/themes/gruvbox-dark.json";
          value = {
            text = opencodeGruvboxDarkTheme;
            force = true;
          };
        }
      ]) opencodeProfileNames
    )
  );

  opencodeImpeccableCommandFiles =
    if cfg.impeccable.enable then
      builtins.listToAttrs (
        lib.flatten (
          map (
            profile:
            map (cmd: {
              name = "${profile}/commands/${cmd.name}.md";
              value = {
                text = impeccable.mkImpeccableCommandText cmd;
                force = true;
              };
            }) impeccable.impeccableCommandDefs
          ) opencodeProfileNames
        )
      )
    else
      { };

  mkTextFiles =
    prefix: templates:
    builtins.listToAttrs (
      lib.mapAttrsToList (name: text: {
        name = "${prefix}/${name}";
        value = { inherit text; };
      }) templates
    );
in
{
  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      # === Claude Agent Definitions ===
      (lib.mkIf cfg.claude.enable (mkTextFiles ".claude/agents" fileTemplates.claudeAgents))

      # === Aider Configuration (independent of any agent enable gate) ===
      {
        ".aider.conf.yml".text = builtins.toJSON {
          model = models.aider-model;
          editor-model = models.aider-editor;
          auto-commits = false;
          dirty-commits = false;
          attribute-author = false;
          attribute-committer = false;
          dark-mode = true;
          pretty = true;
          stream = true;
          map-tokens = 2048;
          map-refresh = "auto";
          auto-lint = true;
          lint-cmd = "just lint";
          auto-test = false;
          test-cmd = "just check";
          suggest-shell-commands = false;
        };
      }

      # === Gemini Files (Settings, Commands, Skills) ===
      (lib.mkIf cfg.gemini.enable (
        {
          ".gemini/settings.json" = {
            text = toJSON geminiSettings;
            force = true;
          };
        }
        // (mkTextFiles ".gemini/commands" fileTemplates.geminiCommands)
        // (mkTextFiles ".gemini/skills" fileTemplates.geminiSkills)
        // (mkTextFiles ".gemini/policies" geminiPolicies)
      ))
    ];

    xdg.configFile = lib.mkMerge [
      # Runtime model/service config for shell scripts (always available when agents enabled)
      (lib.mkIf cfg.enable {
        "ai-agents/models.sh" = {
          text = agentEnvContent;
          force = true;
        };
      })
      # OpenCode profile configs
      (lib.mkIf cfg.opencode.enable (opencodeConfigFiles // opencodeImpeccableCommandFiles))
    ];
  };
}
