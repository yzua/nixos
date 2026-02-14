# MCP server definitions and logging configuration.
{ config, constants, ... }:

{
  programs.aiAgents = {
    mcpServers = {
      context7 = {
        enable = true;
        command = "context7-mcp";
      };

      zai-mcp-server = {
        enable = true;
        command = "bunx";
        args = [ "@z_ai/mcp-server" ];
        env = {
          Z_AI_MODE = "ZAI";
        };
      };

      web-search-prime = {
        enable = false;
        type = "remote";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
      };

      filesystem = {
        enable = true;
        command = "mcp-server-filesystem";
        args = [ "/home/yz" ];
      };

      git = {
        enable = false; # gitpython cannot GPG-sign commits; use Bash(git *) instead
        command = "uvx";
        args = [ "mcp-server-git" ];
      };

      memory = {
        enable = true;
        command = "mcp-server-memory";
      };

      sequential-thinking = {
        enable = true;
        command = "mcp-server-sequential-thinking";
      };

      playwright = {
        enable = true;
        command = "playwright-mcp";
        args = [
          "--executable-path"
          "/run/current-system/sw/bin/chromium"
        ];
      };

      cloudflare-docs = {
        enable = true;
        type = "remote";
        url = "https://docs.mcp.cloudflare.com/mcp";
      };

      cloudflare-workers-builds = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://builds.mcp.cloudflare.com/mcp";
      };

      cloudflare-workers-bindings = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://bindings.mcp.cloudflare.com/mcp";
      };

      cloudflare-observability = {
        enable = false; # never connects, wastes startup time
        type = "remote";
        url = "https://observability.mcp.cloudflare.com/mcp";
      };

      github = {
        enable = true;
        command = "mcp-server-github";
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
