# OpenCode model selections, provider registries, and tool configurations.

{
  config,
  lib,
  ...
}:

let
  models = import ../../helpers/_models.nix;
  workflowPrompts = import ../../helpers/_workflow-prompts.nix { };
  opencodeAgents = import ./_opencode-agents.nix { inherit models; };
  opencodeCommands = import ./_opencode-commands.nix { inherit workflowPrompts; };
  androidReAgent = import ./_opencode-android-re.nix {
    inherit config lib;
    inherit (opencodeAgents) yoloPermission;
  };
  webReAgent = import ./_opencode-web-re.nix {
    inherit config lib;
    inherit (opencodeAgents) yoloPermission;
  };
in
{
  programs.aiAgents.opencode = {
    enable = true;
    model = models.claude-opus;
    defaultAgent = "build";
    permission = opencodeAgents.yoloPermission;

    plugins = [
      "opencode-gemini-auth@latest"
    ];

    command = opencodeCommands;

    agent = { } // androidReAgent // webReAgent;

    lsp = import ./_opencode-lsp.nix;

    experimental = {
      batch_tool = true;
      continue_loop_on_deny = true;
      mcp_timeout = 120000;
      openTelemetry = config.programs.aiAgents.logging.enableOtel;
    };

    extraSettings = {
      share = "disabled";
      autoupdate = true;
      small_model = models.zen; # Free model for titles, summaries
    };

    providers = {
      openrouter = {
        options = {
          apiKey = "__OPENROUTER_API_KEY_PLACEHOLDER__";
        };
      };
    };
  };
}
