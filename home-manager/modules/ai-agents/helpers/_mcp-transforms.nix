# MCP server transformation functions.

{ cfg, lib }:

let
  sharedMcpServers = cfg.mcpServers;

  mkMcpTransform =
    {
      localAttrs,
      remoteAttrs,
      envKey ? "env",
    }:
    lib.mapAttrs (
      _: server:
      let
        isLocal = (server.type or "local") == "local";
        base = if isLocal then localAttrs server else remoteAttrs server;
        envAttrs = lib.optionalAttrs (server.env or { } != { }) {
          ${envKey} = server.env;
        };
      in
      base // envAttrs
    ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  claudeMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs =
      server:
      {
        type = "http";
        inherit (server) url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });
  };

  opencodeMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs =
      server:
      {
        type = "remote";
        inherit (server) url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });
    envKey = "environment";
  };

  geminiMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs =
      server:
      {
        httpUrl = server.url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });
  };

in
{
  inherit
    sharedMcpServers
    claudeMcpServers
    opencodeMcpServers
    geminiMcpServers
    ;
}
