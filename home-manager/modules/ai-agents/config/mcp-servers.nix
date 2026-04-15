# MCP server definitions and logging configuration.

{ config, constants, ... }:

let
  zai = import ../helpers/_zai-services.nix { inherit constants; };

  mkZaiRemoteMcp = path: {
    enable = true;
    type = "remote";
    url = "${zai.baseUrl}/${path}/mcp";
    headers = {
      Authorization = "Bearer {env:ZAI_API_KEY}";
    };
  };

  # Derive Z.AI MCP server entries from the services registry — single source of truth.
  zaiMcpServers = builtins.listToAttrs (
    map (svc: {
      name = svc.mcpKey;
      value = mkZaiRemoteMcp svc.name;
    }) zai.services
  );
in
{
  programs.aiAgents = {
    mcpServers = zaiMcpServers // {
      context7 = {
        enable = true;
        command = "bunx";
        args = [
          "@upstash/context7-mcp@2.1.2"
        ];
        env = {
          CONTEXT7_API_KEY = "__CONTEXT7_API_KEY_PLACEHOLDER__"; # patched at activation from sops secret
        };
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
