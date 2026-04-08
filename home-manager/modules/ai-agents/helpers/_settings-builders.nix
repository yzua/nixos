# Per-agent settings builders and profile variant overrides.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  mcpTransforms = import ./_mcp-transforms.nix { inherit config lib; };
  formatterRegistry = import ../config/_formatters.nix;
  inherit (mcpTransforms) opencodeMcpServers geminiMcpServers;
  sonnetModel = "anthropic/claude-sonnet-4-6";
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
    inherit (cfg.gemini) theme sandboxMode;
  }
  // (lib.optionalAttrs (cfg.globalInstructions != "") {
    systemInstruction = cfg.globalInstructions;
  })
  // (lib.optionalAttrs (cfg.gemini.extraSettings != { }) cfg.gemini.extraSettings);

  openrouterModel = "openrouter/openrouter/hunter-alpha";

  mkProfileSettings =
    { model }:
    {
      opencode = opencodeSettings // {
        inherit model;
      };
    };

  profiles = {
    glm = mkProfileSettings {
      model = "zai-coding-plan/glm-5.1";
    };

    gemini = mkProfileSettings {
      model = "google/antigravity-gemini-3.1-pro";
    };

    gpt = mkProfileSettings {
      model = "openai/gpt-5.4";
    };

    openrouter = mkProfileSettings {
      model = openrouterModel;
    };

    zen = mkProfileSettings {
      model = "opencode/minimax-m2.5-free";
    };
  };

  sonnetProfile = {
    opencode = opencodeSettings // {
      model = sonnetModel;
    };
  };

  glmOpencodeSettings = profiles.glm.opencode;
  geminiOpencodeSettings = profiles.gemini.opencode;
  gptOpencodeSettings = profiles.gpt.opencode;
  openrouterOpencodeSettings = profiles.openrouter.opencode;
  sonnetOpencodeSettings = sonnetProfile.opencode;
  zenOpencodeSettings = profiles.zen.opencode;
in
{
  inherit
    claudeSettings
    opencodeSettings
    geminiSettings
    glmOpencodeSettings
    geminiOpencodeSettings
    gptOpencodeSettings
    openrouterOpencodeSettings
    sonnetOpencodeSettings
    zenOpencodeSettings
    ;
}
