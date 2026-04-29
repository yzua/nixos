# Generates a shell-sourceable config file with model IDs and service endpoints.
# Bridges the Nix single-source-of-truth (_models.nix, constants.nix) to runtime
# shell scripts (scripts/ai/_agent-registry.sh).
# Written to ~/.config/ai-agents/models.sh by files.nix.

let
  models = import ./_models.nix;
  zaiConfig = import ./_zai-config.nix;

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
    "# ZAI service config (source: helpers/_zai-config.nix)"
    "ZAI_API_ROOT='${zaiConfig.apiRoot}'"
    "ZAI_TIMEOUT='${toString zaiConfig.timeout}'"
    "ZAI_MODEL_HAIKU='${zaiConfig.models.haiku}'"
    "ZAI_MODEL_SONNET='${zaiConfig.models.sonnet}'"
    "ZAI_MODEL_OPUS='${zaiConfig.models.opus}'"
  ];
in
builtins.concatStringsSep "\n" lines + "\n"
