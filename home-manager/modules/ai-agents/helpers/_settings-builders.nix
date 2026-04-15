# Per-agent settings builders and profile variant overrides.

{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.aiAgents;
  mcpTransforms = import ./_mcp-transforms.nix { inherit config lib; };
  formatterRegistry = import ./_formatters.nix;
  models = import ./_models.nix;
  inherit (mcpTransforms) opencodeMcpServers geminiMcpServers;
  opencodeFormatterSettings = builtins.listToAttrs (
    map (formatter: {
      name = formatter.tool;
      value = {
        command = lib.splitString " " formatter.command;
        inherit (formatter) extensions;
      };
    }) formatterRegistry.formatters
  );

  mkOptionalOpencodeSetting =
    key: value:
    if builtins.isAttrs value then
      lib.optionalAttrs (value != { }) { ${key} = value; }
    else if builtins.isList value then
      lib.optionalAttrs (value != [ ]) { ${key} = value; }
    else
      lib.optionalAttrs (value != null) { ${key} = value; };

  claudeSettings = {
    inherit (cfg.claude) model permissions hooks;
    env =
      cfg.claude.env
      // (lib.optionalAttrs cfg.logging.enableOtel {
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = cfg.logging.otelExporter;
        OTEL_EXPORTER_OTLP_ENDPOINT = cfg.logging.otelEndpoint;
      });
  }
  // (lib.optionalAttrs (cfg.claude.extraSettings != { }) cfg.claude.extraSettings);

  opencodeSettings = {
    "$schema" = "https://opencode.ai/config.json";
    inherit (cfg.opencode) model;
    mcp = opencodeMcpServers;
    plugin = cfg.opencode.plugins;
    provider = cfg.opencode.providers;
    # Disable snapshot system to prevent tmp_pack_* file leaks and disk bloat (#14811)
    snapshot = false;
    watcher.ignore = [
      "node_modules/**"
      "dist/**"
      ".git/**"
      ".venv/**"
      "target/**"
      "build/**"
      "coverage/**"
      "__pycache__/**"
      ".next/**"
      "result/**"
    ];
  }
  // (mkOptionalOpencodeSetting "permission" cfg.opencode.permission)
  // (mkOptionalOpencodeSetting "agent" cfg.opencode.agent)
  // (mkOptionalOpencodeSetting "command" cfg.opencode.command)
  // (mkOptionalOpencodeSetting "lsp" cfg.opencode.lsp)
  // (mkOptionalOpencodeSetting "formatter" (
    if cfg.opencode.formatter == { } then opencodeFormatterSettings else cfg.opencode.formatter
  ))
  // (mkOptionalOpencodeSetting "experimental" cfg.opencode.experimental)
  // (mkOptionalOpencodeSetting "default_agent" cfg.opencode.defaultAgent)
  // (mkOptionalOpencodeSetting "enabled_providers" cfg.opencode.enabledProviders)
  // (mkOptionalOpencodeSetting "disabled_providers" cfg.opencode.disabledProviders)
  // (lib.optionalAttrs (cfg.globalInstructions != "") { instructions = [ cfg.globalInstructions ]; })
  // (lib.optionalAttrs (cfg.opencode.extraSettings != { }) cfg.opencode.extraSettings);

  geminiSettings = {
    mcpServers = geminiMcpServers;
  }
  // (lib.optionalAttrs (cfg.globalInstructions != "") {
    systemInstruction = cfg.globalInstructions;
  })
  // (lib.optionalAttrs (cfg.gemini.extraSettings != { }) cfg.gemini.extraSettings);

  mkProfileSettings =
    { model }:
    {
      opencode = opencodeSettings // {
        inherit model;
      };
    };

  profiles = {
    glm = mkProfileSettings { model = models.glm; };
    gemini = mkProfileSettings { model = models.gemini; };
    gpt = mkProfileSettings { model = models.gpt-default; };
    openrouter = mkProfileSettings { model = models.openrouter; };
    zen = mkProfileSettings { model = models.zen; };
  };

  # Profile variant settings keyed by profile name (matching _opencode-profiles.nix names).
  opencodeSettingsByProfile = {
    opencode = opencodeSettings;
    "opencode-glm" = profiles.glm.opencode;
    "opencode-gemini" = profiles.gemini.opencode;
    "opencode-gpt" = profiles.gpt.opencode;
    "opencode-openrouter" = profiles.openrouter.opencode;
    "opencode-sonnet" = opencodeSettings // {
      model = models.claude-sonnet;
    };
    "opencode-zen" = profiles.zen.opencode;
  };
in
{
  inherit
    claudeSettings
    opencodeSettings
    geminiSettings
    opencodeSettingsByProfile
    ;
}
