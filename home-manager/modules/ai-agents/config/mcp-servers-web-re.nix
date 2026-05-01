# Web RE agent-specific MCP servers.
# These are only loaded into the web-re agent's runtime config,
# not shared with other agents (build, plan, review, etc.).

_args: {
  programs.aiAgents = {
    webReMcpServers = {
      # chrome-devtools is already shared globally.
      # Add web-re-specific servers here in the future.
    };
  };
}
