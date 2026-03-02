# MCP server definitions and logging configuration.
{ config, ... }:

{
  programs.aiAgents = {
    mcpServers = {
      context7 = {
        enable = true;
        command = "bunx";
        args = [
          "@upstash/context7-mcp@2.1.2"
        ];
      };

      web-search-prime = {
        enable = true;
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
      };

      web-reader = {
        enable = true;
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
      };

      zread = {
        enable = true;
        type = "remote";
        url = "https://api.z.ai/api/mcp/zread/mcp";
      };

      cloudflare-docs = {
        enable = true;
        type = "remote";
        url = "https://docs.mcp.cloudflare.com/mcp";
      };

      github = {
        enable = true;
        command = "bunx";
        args = [
          "@modelcontextprotocol/server-github@2025.4.8"
        ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "__GITHUB_TOKEN_PLACEHOLDER__"; # patched at activation via gh auth token
        };
      };

    };

    logging = {
      enable = true;
      directory = "${config.xdg.dataHome}/ai-agents/logs";
      notifyOnError = true;
      retentionDays = 30;

      enableOtel = false;
    };
  };
}
