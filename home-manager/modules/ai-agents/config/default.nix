# Import hub for split AI agent configuration files.

{
  imports = [
    ./instructions.nix # Global instructions and skills
    ./mcp-servers.nix # MCP server definitions and logging
    ./models # Model/provider registries (OpenCode, Codex, Gemini)
    ./claude # Claude Code permissions, hooks, and settings
  ];
}
