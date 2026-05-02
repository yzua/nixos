# MCP server transformation functions.

{ cfg, lib }:

let
  inherit (cfg)
    mcpServers
    androidReMcpServers
    webReMcpServers
    ;
  sharedMcpServers = mcpServers;

  # Headers are shared across all remote transforms — apply once in the factory.
  withOptionalHeaders =
    attrs: server:
    attrs // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; });

  mkMcpTransform =
    {
      localAttrs,
      remoteAttrs,
      envKey ? "env",
      servers ? sharedMcpServers,
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
    ) (lib.filterAttrs (_: s: s.enable) servers);

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

  ompMcpServers = mkMcpTransform {
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

  opencodeAndroidReMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
    servers = androidReMcpServers;
  };

  opencodeWebReMcpServers = mkMcpTransform {
    localAttrs = server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    };
    remoteAttrs = server: {
      type = "remote";
      inherit (server) url;
    };
    envKey = "environment";
    servers = webReMcpServers;
  };

  ompAndroidReMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
    servers = androidReMcpServers;
  };

  ompWebReMcpServers = mkMcpTransform {
    localAttrs = server: {
      inherit (server) command;
      args = server.args or [ ];
    };
    remoteAttrs = server: {
      type = "http";
      inherit (server) url;
    };
    servers = webReMcpServers;
  };

in
{
  inherit
    sharedMcpServers
    claudeMcpServers
    ompMcpServers
    ompAndroidReMcpServers
    ompWebReMcpServers
    opencodeMcpServers
    geminiMcpServers
    opencodeAndroidReMcpServers
    opencodeWebReMcpServers
    ;
}
