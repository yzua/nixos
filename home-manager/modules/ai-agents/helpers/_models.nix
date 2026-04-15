# Single source of truth for model identifiers used across AI agent configs.
# When upgrading a model, change it here — all consumers pick it up automatically.

{
  # Anthropic Claude models
  claude-opus = "anthropic/claude-opus-4-6";
  claude-sonnet = "anthropic/claude-sonnet-4-6";
  claude-haiku = "anthropic/claude-haiku-4-5";

  # OpenAI models
  gpt-default = "openai/gpt-5.4";
  gpt-low = "openai/gpt-5.4-spark";
  gpt-xhigh = "openai/gpt-5.1-codex-max";

  # Provider-specific aliases
  openrouter = "openrouter/openrouter/hunter-alpha";

  # ZAI / other
  glm = "zai-coding-plan/glm-5.1";
  gemini = "google/gemini-3-pro-preview";
  zen = "opencode/minimax-m2.5-free";

  # Aider (uses Anthropic model IDs without provider prefix)
  aider-model = "claude-sonnet-4-6";
  aider-editor = "claude-haiku-4-5";
}
