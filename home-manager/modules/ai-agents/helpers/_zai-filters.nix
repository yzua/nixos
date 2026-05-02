# Generates agent-specific jq filters for Z.AI MCP secret injection.
#
# Each agent uses a different JSON key path and schema variant:
#   - opencode: .mcp["<key>"], type "remote"
#   - claude:   .mcpServers["<key>"], type "http"
#   - gemini:   .mcpServers["<key>"], type "http", extra command/args fields

{ lib }:

let
  zai = import ./_zai-services.nix;

  mkServiceEntries =
    {
      mcpRoot,
      type,
      extraFields ? { },
    }:
    lib.concatStringsSep " |\n    " (
      map (
        svc:
        let
          extraFieldLines = lib.mapAttrsToList (k: v: "${k}: ${v}") extraFields;
          objectLines = [
            (lib.optionalString (type != null) ''type: "${type}"'')
            ''url: "${zai.baseUrl}/${svc.name}/mcp"''
            ''headers: { Authorization: ("Bearer " + $key) }''
          ]
          ++ extraFieldLines;
          renderedLines = lib.concatStringsSep ",\n            " (
            builtins.filter (line: line != "") objectLines
          );
        in
        ''
          .${mcpRoot}["${svc.mcpKey}"] = {
            ${renderedLines}
          }''
      ) zai.services
    );

  mkZaiFilter =
    {
      mcpRoot,
      nativeKey,
      type,
      extraFields ? { },
    }:
    let
      serviceEntries = mkServiceEntries { inherit mcpRoot type extraFields; };
    in
    ''
      (if .${mcpRoot}["${nativeKey}"] != null then .${mcpRoot}["${nativeKey}"].${
        if mcpRoot == "mcp" then "environment" else "env"
      }.Z_AI_API_KEY = $key else . end) |
        ${serviceEntries}'';

in
{
  opencodeZaiFilter = mkZaiFilter {
    mcpRoot = "mcp";
    nativeKey = "zai-mcp-server";
    type = "remote";
  };

  claudeZaiFilter = mkZaiFilter {
    mcpRoot = "mcpServers";
    nativeKey = "zai-mcp-server";
    type = "http";
  };

  ompZaiFilter = mkZaiFilter {
    mcpRoot = "mcpServers";
    nativeKey = "zai-mcp-server";
    type = "http";
  };

  geminiZaiFilter = mkZaiFilter {
    mcpRoot = "mcpServers";
    nativeKey = "zai-mcp-server";
    type = "http";
    extraFields = {
      command = ''"echo"'';
      args = "[]";
    };
  };
}
