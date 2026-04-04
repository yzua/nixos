# MCP server definitions and logging configuration.

{ config, ... }:

let
  mkZaiRemoteMcp = path: {
    enable = true;
    type = "remote";
    url = "https://api.z.ai/api/mcp/${path}/mcp";
    headers = {
      Authorization = "Bearer {env:ZAI_API_KEY}";
    };
  };
in
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

      web-search-prime = mkZaiRemoteMcp "web_search_prime";
      web-reader = mkZaiRemoteMcp "web_reader";
      zread = mkZaiRemoteMcp "zread";

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

      chrome-devtools = {
        enable = true;
        command = "npx";
        args = [
          "-y"
          "chrome-devtools-mcp@latest"
          "--autoConnect"
        ];
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
