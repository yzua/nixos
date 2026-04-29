# Shared ZAI provider environment variables.
# Single source of truth for the env var block used by claude_glm (functions.nix)
# and Android RE launchers (_android-re-launchers.nix).
# The API key must be set separately by the caller (different loading mechanisms).

let
  zaiConfig = import ./_zai-config.nix;
  inherit (zaiConfig) timeout;
  inherit (zaiConfig.models) haiku sonnet opus;

  envVars = [
    {
      name = "ANTHROPIC_BASE_URL";
      value = "${zaiConfig.apiRoot}/anthropic";
    }
    {
      name = "API_TIMEOUT_MS";
      value = toString timeout;
    }
    {
      name = "ANTHROPIC_DEFAULT_HAIKU_MODEL";
      value = haiku;
    }
    {
      name = "ANTHROPIC_DEFAULT_SONNET_MODEL";
      value = sonnet;
    }
    {
      name = "ANTHROPIC_DEFAULT_OPUS_MODEL";
      value = opus;
    }
  ];
in
{
  inherit envVars;

  # Inline bash prefix: VAR=val \  (for inline env before a command)
  inlinePrefix = builtins.concatStringsSep " \\\n  " (map (v: "${v.name}=\"${v.value}\"") envVars);

  # Export block: export VAR=val\n (for script embedding)
  exportBlock = builtins.concatStringsSep "\n" (map (v: "export ${v.name}=\"${v.value}\"") envVars);
}
