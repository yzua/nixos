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
  gptStandardModel = "openai/gpt-5.3-codex";
  gptFastModel = "opencode/gpt-5-nano";
  openrouterModel = "openrouter/openrouter/hunter-alpha";
  zenMainModel = "opencode/minimax-m2.5-free";
  zenFastModel = "opencode/mimo-v2-flash-free";
  mkCategorySettings =
    categoryModels: categoryVariants:
    lib.mapAttrs (
      category: model:
      {
        inherit model;
      }
      // (lib.optionalAttrs (builtins.hasAttr category categoryVariants) {
        variant = categoryVariants.${category};
      })
    ) categoryModels;
  mkAgentOverrides =
    baseAgents: agentModels: agentVariants:
    lib.mapAttrs (
      name: agentCfg:
      agentCfg
      // (lib.optionalAttrs (builtins.hasAttr name agentModels) {
        model = agentModels.${name};
      })
      // (lib.optionalAttrs (builtins.hasAttr name agentVariants) {
        variant = agentVariants.${name};
      })
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

  glmCategoryModels = {
    "visual-engineering" = "zai-coding-plan/glm-5";
    ultrabrain = "zai-coding-plan/glm-5";
    deep = "zai-coding-plan/glm-5";
    artistry = "zai-coding-plan/glm-5";
    quick = "zai-coding-plan/glm-4.7-flash";
    "unspecified-low" = "zai-coding-plan/glm-4.7";
    "unspecified-high" = "zai-coding-plan/glm-5";
    writing = "zai-coding-plan/glm-4.7";
  };

  # Gemini profile: Google Gemini models for Gemini-native coding sessions.
  geminiAgentModels = {
    sisyphus = "google/gemini-2.5-pro";
    oracle = "google/gemini-2.5-pro";
    librarian = "google/gemini-2.5-flash";
    explore = "google/gemini-2.5-flash";
    # multimodal-looker keeps its original vision-capable model
    prometheus = "google/gemini-2.5-pro";
    metis = "google/gemini-2.5-pro";
    momus = "google/gemini-2.5-pro";
    atlas = "google/gemini-2.5-flash";
    hephaestus = "google/gemini-2.5-pro";
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
    "visual-engineering" = "google/gemini-2.5-pro";
    ultrabrain = "google/gemini-2.5-pro";
    deep = "google/gemini-2.5-pro";
    artistry = "google/gemini-2.5-pro";
    quick = "google/gemini-2.5-flash";
    "unspecified-low" = "google/gemini-2.5-flash";
    "unspecified-high" = "google/gemini-2.5-pro";
    writing = "google/gemini-2.5-flash";
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

  glmOpencodeSettings = opencodeSettings // {
    model = "zai-coding-plan/glm-5";
  };

  glmOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = mkAgentOverrides ohMyOpencodeSettings.agents glmAgentModels { } // {
      # Autonomous deep worker agent (defaults to openai/gpt-5.3-codex)
      hephaestus = {
        model = "zai-coding-plan/glm-5";
      };
    };

    categories = mkCategorySettings glmCategoryModels { };
  };

  # Gemini profile: Google Gemini models for Gemini-native coding sessions.
  geminiOpencodeSettings = opencodeSettings // {
    model = "google/gemini-2.5-pro";
  };

  geminiOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = mkAgentOverrides ohMyOpencodeSettings.agents geminiAgentModels geminiAgentVariants;

    categories = mkCategorySettings geminiCategoryModels geminiCategoryVariants;
  };

  # GPT profile: OpenAI GPT models for GPT-first coding sessions.
  gptOpencodeSettings = opencodeSettings // {
    model = gptMainModel;
  };

  gptOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = mkAgentOverrides ohMyOpencodeSettings.agents gptAgentModels { };

    categories = mkCategorySettings gptCategoryModels { };
  };

  # OpenRouter profile: Hunter Alpha model across OpenCode and oh-my-opencode agents.
  openrouterAgentModels = lib.mapAttrs (_: _: openrouterModel) ohMyOpencodeSettings.agents;
  openrouterCategoryModels = lib.mapAttrs (_: _: openrouterModel) (
    ohMyOpencodeSettings.categories or { }
  );

  openrouterOpencodeSettings = opencodeSettings // {
    model = openrouterModel;
  };

  openrouterOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = mkAgentOverrides ohMyOpencodeSettings.agents openrouterAgentModels { };

    categories = mkCategorySettings openrouterCategoryModels { };
  };

  # Sonnet profile: Default OpenCode config with Opus replaced by Sonnet for lower cost.
  sonnetOpencodeSettings = opencodeSettings // {
    model = sonnetModel;
  };

  sonnetOhMyOpencodeSettings = replaceOpusWithSonnet ohMyOpencodeSettings;

  # Zen profile: OpenCode free-tier models for low-cost coding sessions.
  zenOpencodeSettings = opencodeSettings // {
    model = zenMainModel;
  };

  zenOhMyOpencodeSettings = ohMyOpencodeSettings // {
    agents = mkAgentOverrides ohMyOpencodeSettings.agents zenAgentModels { };

    categories = mkCategorySettings zenCategoryModels { };
  };
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
