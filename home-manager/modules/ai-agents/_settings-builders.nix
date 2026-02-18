# Per-agent settings builders and profile variant overrides.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  mcpTransforms = import ./_mcp-transforms.nix { inherit config lib pkgs; };
  inherit (mcpTransforms) opencodeMcpServers geminiMcpServers;
  sonnetModel = "anthropic/claude-sonnet-4-6";
  gptMainModel = "openai/gpt-5.3-codex";
  gptStandardModel = "openai/gpt-5.3";
  gptFastModel = "opencode/gpt-5-nano";

  replaceOpusWithSonnet =
    value:
    if builtins.isAttrs value then
      lib.mapAttrs (_: replaceOpusWithSonnet) value
    else if builtins.isList value then
      map replaceOpusWithSonnet value
    else if builtins.isString value && value == "anthropic/claude-opus-4-6" then
      sonnetModel
    else
      value;

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
  }
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

  ohMyOpencodeSettings = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
    google_auth = cfg.opencode.ohMyOpencode.googleAuth;
    agents = lib.mapAttrs (
      _: agent:
      {
        inherit (agent) model;
      }
      // (lib.optionalAttrs (agent.variant != null) { inherit (agent) variant; })
      // (lib.optionalAttrs (agent.prompt != null) { inherit (agent) prompt; })
      // (lib.optionalAttrs (agent.prompt_append != null) { inherit (agent) prompt_append; })
      // (lib.optionalAttrs (agent.skills != null) { inherit (agent) skills; })
      // (lib.optionalAttrs (agent.temperature != null) { inherit (agent) temperature; })
      // (lib.optionalAttrs (agent.top_p != null) { inherit (agent) top_p; })
      // (lib.optionalAttrs (agent.tools != null) { inherit (agent) tools; })
      // (lib.optionalAttrs (agent.description != null) { inherit (agent) description; })
      // (lib.optionalAttrs (agent.mode != null) { inherit (agent) mode; })
      // (lib.optionalAttrs (agent.color != null) { inherit (agent) color; })
      // (lib.optionalAttrs (agent.permission != null) {
        permission = lib.filterAttrs (_: v: v != null) agent.permission;
      })
    ) cfg.opencode.ohMyOpencode.agents;
  }
  // (lib.optionalAttrs (
    cfg.opencode.ohMyOpencode.extraSettings != { }
  ) cfg.opencode.ohMyOpencode.extraSettings);

  # GLM-5 profile: Z.AI GLM models for cost-effective coding sessions.
  glmAgentModels = {
    sisyphus = "zai-coding-plan/glm-5";
    oracle = "zai-coding-plan/glm-5";
    librarian = "zai-coding-plan/glm-4.7";
    explore = "zai-coding-plan/glm-4.7-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "zai-coding-plan/glm-5";
    metis = "zai-coding-plan/glm-5";
    momus = "zai-coding-plan/glm-4.7";
    atlas = "zai-coding-plan/glm-4.7";
  };

  # Gemini profile: Google Antigravity models for Gemini-native coding sessions.
  geminiAgentModels = {
    sisyphus = "google/antigravity-gemini-3-pro";
    oracle = "google/antigravity-gemini-3-pro";
    librarian = "google/antigravity-gemini-3-flash";
    explore = "google/antigravity-gemini-3-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "google/antigravity-gemini-3-pro";
    metis = "google/antigravity-gemini-3-pro";
    momus = "google/antigravity-gemini-3-pro";
    atlas = "google/antigravity-gemini-3-flash";
    hephaestus = "google/antigravity-gemini-3-pro";
  };

  # Variant overrides for Gemini agents (thinking levels per role).
  geminiAgentVariants = {
    prometheus = "high"; # Strategic planning — max thinking
    momus = "low"; # Plan review — lighter thinking
    librarian = "medium"; # Reference search — moderate
    atlas = "medium"; # Coordination — moderate
    explore = "minimal"; # Fast grep — speed over depth
  };

  # GPT profile: OpenAI GPT models for GPT-first coding sessions.
  gptAgentModels = {
    sisyphus = gptMainModel;
    oracle = gptStandardModel;
    librarian = gptStandardModel;
    explore = gptFastModel;
    # multimodal-looker keeps its original vision-capable model
    prometheus = gptMainModel;
    metis = gptMainModel;
    momus = gptStandardModel;
    atlas = gptStandardModel;
    hephaestus = gptMainModel;
  };

  glmOpencodeSettings = opencodeSettings // {
    model = "zai-coding-plan/glm-5";
  };

  glmOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents =
      lib.mapAttrs (
        name: agentCfg:
        agentCfg
        // (lib.optionalAttrs (builtins.hasAttr name glmAgentModels) {
          model = glmAgentModels.${name};
        })
      ) ohMyOpencodeSettings.agents
      // {
        # Autonomous deep worker agent (defaults to openai/gpt-5.3-codex)
        hephaestus = {
          model = "zai-coding-plan/glm-5";
        };
      };

    # Override category models to use GLM instead of default providers
    categories = {
      "visual-engineering" = {
        model = "zai-coding-plan/glm-5";
      };
      ultrabrain = {
        model = "zai-coding-plan/glm-5";
      };
      deep = {
        model = "zai-coding-plan/glm-5";
      };
      artistry = {
        model = "zai-coding-plan/glm-5";
      };
      quick = {
        model = "zai-coding-plan/glm-4.7-flash";
      };
      "unspecified-low" = {
        model = "zai-coding-plan/glm-4.7";
      };
      "unspecified-high" = {
        model = "zai-coding-plan/glm-5";
      };
      writing = {
        model = "zai-coding-plan/glm-4.7";
      };
    };
  };

  # Gemini profile: Google Antigravity models for Gemini-native coding sessions.
  geminiOpencodeSettings = opencodeSettings // {
    model = "google/antigravity-gemini-3-pro";
  };

  geminiOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = lib.mapAttrs (
      name: agentCfg:
      agentCfg
      // (lib.optionalAttrs (builtins.hasAttr name geminiAgentModels) {
        model = geminiAgentModels.${name};
      })
      // (lib.optionalAttrs (builtins.hasAttr name geminiAgentVariants) {
        variant = geminiAgentVariants.${name};
      })
    ) ohMyOpencodeSettings.agents;

    # Override category models to use Gemini Antigravity instead of default providers
    categories = {
      "visual-engineering" = {
        model = "google/antigravity-gemini-3-pro";
      };
      ultrabrain = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      deep = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      artistry = {
        model = "google/antigravity-gemini-3-pro";
      };
      quick = {
        model = "google/antigravity-gemini-3-flash";
        variant = "minimal";
      };
      "unspecified-low" = {
        model = "google/antigravity-gemini-3-flash";
        variant = "medium";
      };
      "unspecified-high" = {
        model = "google/antigravity-gemini-3-pro";
        variant = "high";
      };
      writing = {
        model = "google/antigravity-gemini-3-flash";
        variant = "medium";
      };
    };
  };

  # GPT profile: OpenAI GPT models for GPT-first coding sessions.
  gptOpencodeSettings = opencodeSettings // {
    model = gptMainModel;
  };

  gptOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = lib.mapAttrs (
      name: agentCfg:
      agentCfg
      // (lib.optionalAttrs (builtins.hasAttr name gptAgentModels) {
        model = gptAgentModels.${name};
      })
    ) ohMyOpencodeSettings.agents;

    # Override category models to use GPT defaults instead of mixed providers
    categories = {
      "visual-engineering" = {
        model = gptMainModel;
      };
      ultrabrain = {
        model = gptMainModel;
      };
      deep = {
        model = gptMainModel;
      };
      artistry = {
        model = gptMainModel;
      };
      quick = {
        model = gptFastModel;
      };
      "unspecified-low" = {
        model = gptStandardModel;
      };
      "unspecified-high" = {
        model = gptMainModel;
      };
      writing = {
        model = gptStandardModel;
      };
    };
  };

  # Sonnet profile: Default OpenCode config with Opus replaced by Sonnet for lower cost.
  sonnetOpencodeSettings = opencodeSettings // {
    model = sonnetModel;
  };

  sonnetOhMyOpencodeSettings = replaceOpusWithSonnet ohMyOpencodeSettings;
in
{
  inherit
    claudeSettings
    opencodeSettings
    geminiSettings
    ohMyOpencodeSettings
    glmOpencodeSettings
    glmOhMyOpencodeSettings
    geminiOpencodeSettings
    geminiOhMyOpencodeSettings
    gptOpencodeSettings
    gptOhMyOpencodeSettings
    sonnetOpencodeSettings
    sonnetOhMyOpencodeSettings
    ;
}
