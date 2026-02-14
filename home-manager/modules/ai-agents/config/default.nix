# Import hub for split AI agent configuration files.
{
  imports = [
    ./instructions.nix # Global instructions and skills
    ./mcp-servers.nix # MCP server definitions and logging
    ./permissions.nix # Claude permissions, hooks, and settings
    ./models.nix # Model/provider registries (OpenCode, Codex, Gemini)
    ./agents.nix # Oh-My-OpenCode agent definitions
  ];
}
