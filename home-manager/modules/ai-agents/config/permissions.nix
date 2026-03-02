# Claude Code permissions, lifecycle hooks, and extra settings.
_:

let
  claudePermissionRules = import ./_claude-permission-rules.nix;
  claudeHooks = import ./_claude-hooks.nix;
in
{
  programs.aiAgents = {
    claude = {
      enable = true;
      model = "opus";

      env = {
        EDITOR = "nvim";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        MAX_MCP_OUTPUT_TOKENS = "50000"; # Default 10k; raised for large codebases
        MCP_TIMEOUT = "30000"; # Default 10s; raised for npx cold starts
        ENABLE_TOOL_SEARCH = "auto:5"; # Auto-search when >5 tools match; faster with 12+ MCPs
        ENABLE_CLAUDEAI_MCP_SERVERS = "false"; # Keep MCP surface declarative via ~/.mcp.json
      };

      permissions = claudePermissionRules;
      hooks = claudeHooks;

      # === Extra Settings ===
      extraSettings = {
        cleanupPeriodDays = 14;
        respectGitignore = true;
        alwaysThinkingEnabled = true;
        showTurnDuration = true;
        spinnerTipsEnabled = true;
        autoUpdatesChannel = "latest";
        prefersReducedMotion = false;
        attribution = {
          commit = "";
          pr = "";
        };
      };
    };
  };
}
