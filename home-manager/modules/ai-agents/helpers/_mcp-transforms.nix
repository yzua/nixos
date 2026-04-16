# MCP server transformation functions.

{ cfg, lib }:

let
  sharedMcpServers = cfg.mcpServers;

  # Headers are shared across all remote transforms — apply once in the factory.
  withOptionalHeaders =
    attrs: server:
    attrs // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });

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
        base = if isLocal then localAttrs server else withOptionalHeaders (remoteAttrs server) server;
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
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
  };

  opencodeMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
  };

  geminiMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      httpUrl = server.url;
    };
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
