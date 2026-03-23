# Home file and XDG config file declarations for AI agents.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  inherit (builtins) toJSON;

  fileTemplates = import ./_file-templates.nix;
  settingsBuilders = import ./_settings-builders.nix { inherit config lib pkgs; };
  inherit (settingsBuilders)
    opencodeSettings
    geminiSettings
    ohMyOpencodeSettings
    glmOpencodeSettings
    glmOhMyOpencodeSettings
    geminiOpencodeSettings
    geminiOhMyOpencodeSettings
    gptOpencodeSettings
    gptOhMyOpencodeSettings
    openrouterOpencodeSettings
    openrouterOhMyOpencodeSettings
    sonnetOpencodeSettings
    sonnetOhMyOpencodeSettings
    zenOpencodeSettings
    zenOhMyOpencodeSettings
    ;

  opencodeProfiles = import ./_opencode-profiles.nix { inherit config; };
  opencodeProfileNames = opencodeProfiles.names;

  opencodeSettingsByProfile = {
    opencode = opencodeSettings;
    "opencode-glm" = glmOpencodeSettings;
    "opencode-gemini" = geminiOpencodeSettings;
    "opencode-gpt" = gptOpencodeSettings;
    "opencode-openrouter" = openrouterOpencodeSettings;
    "opencode-sonnet" = sonnetOpencodeSettings;
    "opencode-zen" = zenOpencodeSettings;
  };

  impeccableCommandDefs = [
    {
      name = "teach-impeccable";
      description = "One-time setup: gather design context, save to config";
    }
    {
      name = "audit";
      description = "Run technical quality checks";
    }
    {
      name = "critique";
      description = "UX design review";
    }
    {
      name = "normalize";
      description = "Align with design system standards";
    }
    {
      name = "polish";
      description = "Final pass before shipping";
    }
    {
      name = "distill";
      description = "Strip to essence";
    }
    {
      name = "clarify";
      description = "Improve unclear UX copy";
    }
    {
      name = "optimize";
      description = "Performance improvements";
    }
    {
      name = "harden";
      description = "Error handling, i18n, edge cases";
    }
    {
      name = "animate";
      description = "Add purposeful motion";
    }
    {
      name = "colorize";
      description = "Introduce strategic color";
    }
    {
      name = "bolder";
      description = "Amplify boring designs";
    }
    {
      name = "quieter";
      description = "Tone down overly bold designs";
    }
    {
      name = "delight";
      description = "Add moments of joy";
    }
    {
      name = "extract";
      description = "Pull into reusable components";
    }
    {
      name = "adapt";
      description = "Adapt for different devices";
    }
    {
      name = "onboard";
      description = "Design onboarding flows";
    }
    {
      name = "typeset";
      description = "Fix font choices, hierarchy, sizing";
    }
    {
      name = "arrange";
      description = "Fix layout, spacing, visual rhythm";
    }
    {
      name = "overdrive";
      description = "Add technically extraordinary effects";
    }
  ];

  mkImpeccableCommandText = cmd: ''
    ---
    description: ${cmd.description}
    ---

    Use the `${cmd.name}` skill from the installed Impeccable pack.

    Target: $ARGUMENTS
    If no target is provided, apply it to the most relevant current UI surface.
  '';

  ohMyOpencodeSettingsByProfile = {
    opencode = ohMyOpencodeSettings;
    "opencode-glm" = glmOhMyOpencodeSettings;
    "opencode-gemini" = geminiOhMyOpencodeSettings;
    "opencode-gpt" = gptOhMyOpencodeSettings;
    "opencode-openrouter" = openrouterOhMyOpencodeSettings;
    "opencode-sonnet" = sonnetOhMyOpencodeSettings;
    "opencode-zen" = zenOhMyOpencodeSettings;
  };

  opencodeConfigFiles = lib.foldl' (
    acc: name:
    acc
    // {
      "${name}/opencode.json" = {
        text = toJSON opencodeSettingsByProfile.${name};
        force = true;
      };
      "${name}/tui.json" = {
        text = toJSON {
          theme = "gruvbox";
          show_tokens = true;
          show_cost = true;
        };
        force = true;
      };
    }
    // (lib.optionalAttrs cfg.opencode.ohMyOpencode.enable {
      "${name}/oh-my-opencode.json" = {
        text = toJSON ohMyOpencodeSettingsByProfile.${name};
        force = true;
      };
    })
  ) { } opencodeProfileNames;

  opencodeImpeccableCommandFiles =
    if cfg.impeccable.enable then
      lib.foldl' (
        acc: profile:
        acc
        // builtins.listToAttrs (
          map (cmd: {
            name = "${profile}/commands/${cmd.name}.md";
            value = {
              text = mkImpeccableCommandText cmd;
              force = true;
            };
          }) impeccableCommandDefs
        )
      ) { } opencodeProfileNames
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

      # === Gemini Files (Settings, Commands, Skills) ===
      (lib.mkIf cfg.gemini.enable (
        {
          ".gemini/settings.json" = {
            text = toJSON geminiSettings;
            force = true;
          };

          # Aider configuration
          ".aider.conf.yml".text = builtins.toJSON {
            model = "claude-sonnet-4-6";
            editor-model = "claude-haiku-4-5";
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
        // (mkTextFiles ".gemini/commands" fileTemplates.geminiCommands)
        // (mkTextFiles ".gemini/skills" fileTemplates.geminiSkills)
      ))
    ];

    xdg.configFile = lib.mkIf cfg.opencode.enable (
      opencodeConfigFiles // opencodeImpeccableCommandFiles
    );
  };
}
