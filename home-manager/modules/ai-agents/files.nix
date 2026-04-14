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

  fileTemplates = import ./helpers/_file-templates.nix;
  geminiPolicies = import ./helpers/_gemini-policies.nix;
  impeccable = import ./helpers/_impeccable-commands.nix;
  settingsBuilders = import ./helpers/_settings-builders.nix { inherit config lib pkgs; };
  inherit (settingsBuilders)
    opencodeSettings
    geminiSettings
    glmOpencodeSettings
    geminiOpencodeSettings
    gptOpencodeSettings
    openrouterOpencodeSettings
    sonnetOpencodeSettings
    zenOpencodeSettings
    ;

  opencodeProfiles = import ./helpers/_opencode-profiles.nix { inherit config; };
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
        };
        force = true;
      };
    }
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
              text = impeccable.mkImpeccableCommandText cmd;
              force = true;
            };
          }) impeccable.impeccableCommandDefs
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
        // (mkTextFiles ".gemini/policies" geminiPolicies)
      ))
    ];

    xdg.configFile = lib.mkIf cfg.opencode.enable (
      opencodeConfigFiles // opencodeImpeccableCommandFiles
    );
  };
}
