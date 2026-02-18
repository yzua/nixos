# MCP server definitions and logging configuration.
{ config, pkgs, ... }:

{
  programs.aiAgents = {
    mcpServers = {
      context7 = {
        enable = true;
        command = "${config.home.homeDirectory}/.bun/bin/context7-mcp";
      };

      zai-mcp-server = {
        enable = true;
        command = "${pkgs.bun}/bin/bunx";
        args = [ "@z_ai/mcp-server" ];
        env = {
          Z_AI_MODE = "ZAI";
        };
      };

      web-search-prime = {
        enable = true;
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
      };

      filesystem = {
        enable = true;
        command = "${config.home.homeDirectory}/.bun/bin/mcp-server-filesystem";
        args = [ config.home.homeDirectory ];
      };

      sequential-thinking = {
        enable = true;
        command = "${config.home.homeDirectory}/.bun/bin/mcp-server-sequential-thinking";
      };

      cloudflare-docs = {
        enable = true;
        type = "remote";
        url = "https://docs.mcp.cloudflare.com/mcp";
      };

      github = {
        enable = true;
        command = "${config.home.homeDirectory}/.bun/bin/mcp-server-github";
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = "__GITHUB_TOKEN_PLACEHOLDER__"; # patched at activation via gh auth token
        };
      };
    };

    logging = {
      enable = true;
      directory = "${config.home.homeDirectory}/.local/share/ai-agents/logs";
      notifyOnError = true;
      retentionDays = 30;

      enableOtel = false;
    };
  };
}
