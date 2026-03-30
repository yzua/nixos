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
  gptModel = "openai/gpt-5.4";
  gptMainModel = gptModel;
  gptStandardModel = gptModel;
  gptFastModel = "opencode/gpt-5-nano";
  openrouterModel = "openrouter/openrouter/hunter-alpha";
  zenMainModel = "opencode/minimax-m2.5-free";
  zenFastModel = "opencode/mimo-v2-flash-free";
  antigravityProModel = "google/antigravity-gemini-3.1-pro";
  antigravityFlashModel = "google/antigravity-gemini-3-flash";
  mkCategorySettings =
    categoryModels: categoryVariants:
    lib.mapAttrs (
      category: model:
      {
        inherit model;
      }
      // lib.optionalAttrs (categoryVariants ? ${category}) {
        variant = categoryVariants.${category};
      }
    ) categoryModels;
  mkAgentOverrides =
    baseAgents: agentModels: agentVariants:
    lib.mapAttrs (
      name: agentCfg:
      agentCfg
      // lib.optionalAttrs (agentModels ? name) {
        model = agentModels.${name};
      }
      // lib.optionalAttrs (agentVariants ? name) {
        variant = agentVariants.${name};
      }
    ) baseAgents;

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
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";
    google_auth = false;
    agents = lib.mapAttrs (
      _: agent:
      {
        inherit (agent) model;
      }
      // lib.filterAttrs (k: v: k != "model" && k != "permission" && v != null) agent
      // lib.optionalAttrs (agent.permission or null != null) {
        permission = lib.filterAttrs (_: v: v != null) agent.permission;
      }
    ) cfg.opencode.ohMyOpencode.agents;
  }
  // (lib.optionalAttrs (
    cfg.opencode.ohMyOpencode.extraSettings != { }
  ) cfg.opencode.ohMyOpencode.extraSettings);

  # GLM-5 profile: Z.AI GLM models for cost-effective coding sessions.
  glmAgentModels = {
    sisyphus = "zai-coding-plan/glm-5.1";
    oracle = "zai-coding-plan/glm-5.1";
    librarian = "zai-coding-plan/glm-4.7";
    explore = "zai-coding-plan/glm-4.7-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "zai-coding-plan/glm-5.1";
    metis = "zai-coding-plan/glm-5.1";
    momus = "zai-coding-plan/glm-4.7";
    atlas = "zai-coding-plan/glm-4.7";
  };

  glmCategoryModels = {
    "visual-engineering" = "zai-coding-plan/glm-5.1";
    ultrabrain = "zai-coding-plan/glm-5.1";
    deep = "zai-coding-plan/glm-5.1";
    artistry = "zai-coding-plan/glm-5.1";
    quick = "zai-coding-plan/glm-4.7-flash";
    "unspecified-low" = "zai-coding-plan/glm-4.7";
    "unspecified-high" = "zai-coding-plan/glm-5.1";
    writing = "zai-coding-plan/glm-4.7";
  };

  # Gemini profile: Google Gemini models for Gemini-native coding sessions.
  geminiAgentModels = {
    sisyphus = antigravityProModel;
    oracle = antigravityProModel;
    librarian = antigravityFlashModel;
    explore = antigravityFlashModel;
    multimodal-looker = antigravityFlashModel;
    prometheus = antigravityProModel;
    metis = antigravityProModel;
    momus = antigravityProModel;
    atlas = antigravityFlashModel;
    hephaestus = antigravityProModel;
  };

  # Variant overrides for Gemini agents (thinking levels per role).
  geminiAgentVariants = {
    prometheus = "high"; # Strategic planning — max thinking
    momus = "low"; # Plan review — lighter thinking
    librarian = "medium"; # Reference search — moderate
    atlas = "medium"; # Coordination — moderate
    explore = "minimal"; # Fast grep — speed over depth
  };

  geminiCategoryModels = {
    "visual-engineering" = antigravityProModel;
    ultrabrain = antigravityProModel;
    deep = antigravityProModel;
    artistry = antigravityProModel;
    quick = antigravityFlashModel;
    "unspecified-low" = antigravityFlashModel;
    "unspecified-high" = antigravityProModel;
    writing = antigravityFlashModel;
  };

  geminiCategoryVariants = {
    ultrabrain = "high";
    deep = "high";
    quick = "minimal";
    "unspecified-low" = "medium";
    "unspecified-high" = "high";
    writing = "medium";
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

  gptCategoryModels = {
    "visual-engineering" = gptMainModel;
    ultrabrain = gptMainModel;
    deep = gptMainModel;
    artistry = gptMainModel;
    quick = gptFastModel;
    "unspecified-low" = gptStandardModel;
    "unspecified-high" = gptMainModel;
    writing = gptStandardModel;
  };

  # Zen profile: OpenCode free-tier models for low-cost coding sessions.
  zenAgentModels = {
    sisyphus = zenMainModel;
    oracle = zenMainModel;
    librarian = zenMainModel;
    explore = zenFastModel;
    # multimodal-looker keeps its original vision-capable model
    prometheus = zenMainModel;
    metis = zenMainModel;
    momus = zenMainModel;
    atlas = zenMainModel;
    hephaestus = zenMainModel;
  };

  zenCategoryModels = {
    "visual-engineering" = zenMainModel;
    ultrabrain = zenMainModel;
    deep = zenMainModel;
    artistry = zenMainModel;
    quick = zenFastModel;
    "unspecified-low" = zenFastModel;
    "unspecified-high" = zenMainModel;
    writing = zenMainModel;
  };

  mkProfileSettings =
    {
      model,
      agentModels ? { },
      categoryModels ? { },
      agentVariants ? { },
      categoryVariants ? { },
      extraAgentOverrides ? { },
    }:
    {
      opencode = opencodeSettings // {
        inherit model;
      };
      ohMyOpencode = ohMyOpencodeSettings // {
        agents =
          mkAgentOverrides ohMyOpencodeSettings.agents agentModels agentVariants // extraAgentOverrides;
        categories = mkCategorySettings categoryModels categoryVariants;
      };
    };

  # Standard profiles — all follow the same pattern.
  profiles = {
    glm = mkProfileSettings {
      model = "zai-coding-plan/glm-5.1";
      agentModels = glmAgentModels;
      categoryModels = glmCategoryModels;
      extraAgentOverrides = {
        hephaestus = {
          model = "zai-coding-plan/glm-5.1";
        };
      };
    };

    gemini = mkProfileSettings {
      model = antigravityProModel;
      agentModels = geminiAgentModels;
      categoryModels = geminiCategoryModels;
      agentVariants = geminiAgentVariants;
      categoryVariants = geminiCategoryVariants;
    };

    gpt = mkProfileSettings {
      model = gptMainModel;
      agentModels = gptAgentModels;
      categoryModels = gptCategoryModels;
    };

    zen = mkProfileSettings {
      model = zenMainModel;
      agentModels = zenAgentModels;
      categoryModels = zenCategoryModels;
    };
  };

  # Special profiles (non-standard transforms)
  openrouterProfile = mkProfileSettings {
    model = openrouterModel;
    agentModels = lib.mapAttrs (_: _: openrouterModel) ohMyOpencodeSettings.agents;
    categoryModels = lib.mapAttrs (_: _: openrouterModel) (ohMyOpencodeSettings.categories or { });
  };

  sonnetProfile = {
    opencode = opencodeSettings // {
      model = sonnetModel;
    };
    ohMyOpencode = replaceOpusWithSonnet ohMyOpencodeSettings;
  };

  # Derived profile settings (each XOpencodeSettings / XOhMyOpencodeSettings)
  glmOpencodeSettings = profiles.glm.opencode;
  glmOhMyOpencodeSettings = profiles.glm.ohMyOpencode;
  geminiOpencodeSettings = profiles.gemini.opencode;
  geminiOhMyOpencodeSettings = profiles.gemini.ohMyOpencode;
  gptOpencodeSettings = profiles.gpt.opencode;
  gptOhMyOpencodeSettings = profiles.gpt.ohMyOpencode;
  openrouterOpencodeSettings = openrouterProfile.opencode;
  openrouterOhMyOpencodeSettings = openrouterProfile.ohMyOpencode;
  sonnetOpencodeSettings = sonnetProfile.opencode;
  sonnetOhMyOpencodeSettings = sonnetProfile.ohMyOpencode;
  zenOpencodeSettings = profiles.zen.opencode;
  zenOhMyOpencodeSettings = profiles.zen.ohMyOpencode;
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
    openrouterOpencodeSettings
    openrouterOhMyOpencodeSettings
    sonnetOpencodeSettings
    sonnetOhMyOpencodeSettings
    zenOpencodeSettings
    zenOhMyOpencodeSettings
    ;
}
