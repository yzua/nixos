# Single source of truth for model identifiers used across AI agent configs.
# When upgrading a model, change it here — all consumers pick it up automatically.

{
  # Anthropic Claude models
  claude-opus = "opencode/claude-opus-4-7";
  claude-sonnet = "opencode/claude-sonnet-4-7";
  claude-haiku = "opencode/claude-haiku-4-5";

  # OpenAI models
  gpt-default = "openai/gpt-5.5";
  gpt-low = "openai/gpt-5.5-spark";
  gpt-xhigh = "openai/gpt-5.1-codex-max";

  # Provider-specific aliases
  openrouter = "openrouter/tencent/hy3-preview:free";

  # ZAI / other
  glm = "zai-coding-plan/glm-5.1";
  gemini = "google/gemini-3-pro-preview";
  zen = "opencode/minimax-m2.5-free";

  # Gemini CLI model IDs (bare names, no provider prefix)
  gemini-pro = "gemini-3-pro-preview";
  gemini-flash = "gemini-2.5-flash";
  gemini-flash-lite = "gemini-2.5-flash-lite";

  # Aider (uses Anthropic model IDs without provider prefix)
  aider-model = "claude-sonnet-4-7";
  aider-editor = "claude-haiku-4-5";

}
