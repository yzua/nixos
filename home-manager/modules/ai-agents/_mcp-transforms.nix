# MCP server transformation functions and agent log wrapper.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  sharedMcpServers = cfg.mcpServers;

  claudeMcpServers = lib.mapAttrs (
    _: server:
    let
      isLocal = (server.type or "local") == "local";
    in
    if isLocal then
      {
        inherit (server) command;
        args = server.args or [ ];
        env = server.env or { };
      }
    else
      {
        type = "http";
        inherit (server) url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; })
  ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  opencodeMcpServers = lib.mapAttrs (
    _: server:
    let
      isLocal = (server.type or "local") == "local";
      base = {
        type = if isLocal then "local" else "remote";
      };
      localAttrs = if isLocal then { command = [ server.command ] ++ (server.args or [ ]); } else { };
      remoteAttrs =
        if !isLocal then
          {
            inherit (server) url;
          }
          // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; })
        else
          { };
      envAttrs = lib.optionalAttrs (server.env or { } != { }) { environment = server.env; };
    in
    base // localAttrs // remoteAttrs // envAttrs
  ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  geminiMcpServers = lib.mapAttrs (
    _: server:
    let
      isLocal = (server.type or "local") == "local";
    in
    if isLocal then
      {
        inherit (server) command;
        args = server.args or [ ];
        env = server.env or { };
      }
    else
      {
        httpUrl = server.url;
      }
      // (lib.optionalAttrs (server.headers or null != null) { inherit (server) headers; })
  ) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      AI_AGENT_NOTIFY_ON_ERROR=${if cfg.logging.notifyOnError then "true" else "false"} \
      exec ${config.home.homeDirectory}/System/scripts/ai/agent-log-wrapper.sh "$@"
  '';

in
{
  inherit
    sharedMcpServers
    claudeMcpServers
    opencodeMcpServers
    geminiMcpServers
    agentLogWrapper
    ;
}
