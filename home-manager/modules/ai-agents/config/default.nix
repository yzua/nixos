# Import hub for split AI agent configuration files.

{
  imports = [
    ./defaults.nix # Enablement, shared instructions, and skill defaults
    ./mcp-servers.nix # MCP server definitions and logging
    ./mcp-servers-android-re.nix # Android RE agent-specific MCP servers (not shared globally)
    ./models # Model/provider registries (OpenCode, Codex, Gemini)
    ./claude # Claude Code permissions, hooks, and settings
  ];
}
