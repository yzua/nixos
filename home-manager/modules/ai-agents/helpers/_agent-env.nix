# Generates a shell-sourceable config file with model IDs and service endpoints.
# Bridges the Nix single-source-of-truth (_models.nix, constants.nix) to runtime
# shell scripts (scripts/ai/_agent-registry.sh).
# Written to ~/.config/ai-agents/models.sh by files.nix.

{ constants }:

let
  models = import ./_models.nix;

  lines = [
    "# Auto-generated model and service config — do not edit."
    "# Regenerate with: just home"
    "# Source: shared/constants.nix, home-manager/modules/ai-agents/helpers/_models.nix"
    ""
    "# Model IDs (source: helpers/_models.nix)"
    "AI_MODEL_GPT_LOW='${models.gpt-low}'"
    "AI_MODEL_GPT_DEFAULT='${models.gpt-default}'"
    "AI_MODEL_GPT_XHIGH='${models.gpt-xhigh}'"
    ""
    "# ZAI service config (source: shared/constants.nix)"
    "ZAI_API_ROOT='${constants.services.zai.apiRoot}'"
    "ZAI_TIMEOUT='${toString constants.services.zai.timeout}'"
    "ZAI_MODEL_HAIKU='${constants.services.zai.models.haiku}'"
    "ZAI_MODEL_SONNET='${constants.services.zai.models.sonnet}'"
    "ZAI_MODEL_OPUS='${constants.services.zai.models.opus}'"
  ];
in
builtins.concatStringsSep "\n" lines + "\n"
