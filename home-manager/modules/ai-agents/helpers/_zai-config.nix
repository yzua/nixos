# Z.AI API configuration — Anthropic-compatible endpoint with MCP support.
# Agent-local config; not shared with NixOS modules.

{
  apiRoot = "https://api.z.ai/api";
  timeout = 300000; # API timeout in ms (5 min)
  models = {
    haiku = "glm-5-turbo";
    sonnet = "glm-5.1";
    opus = "glm-5.1"; # Same model as sonnet — no dedicated opus-tier available
  };
}
