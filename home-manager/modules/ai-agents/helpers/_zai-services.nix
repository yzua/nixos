# Z.AI MCP service registry — single source of truth for service names and base URL.

{ constants }:

let
  baseUrl = "${constants.services.zai.apiRoot}/mcp";
in
rec {
  inherit baseUrl;

  services = [
    {
      name = "web_search_prime";
      mcpKey = "web-search-prime";
    }
    {
      name = "web_reader";
      mcpKey = "web-reader";
    }
    {
      name = "zread";
      mcpKey = "zread";
    }
  ];
}
