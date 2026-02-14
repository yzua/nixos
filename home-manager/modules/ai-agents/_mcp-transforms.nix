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
        type = server.type or "local";
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

  geminiMcpServers = lib.mapAttrs (_: server: {
    inherit (server) command;
    args = server.args or [ ];
    env = server.env or { };
  }) (lib.filterAttrs (_: s: s.enable) sharedMcpServers);

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    #!/usr/bin/env bash

    AGENT_NAME="$1"
    shift

    LOG_DIR="${cfg.logging.directory}"
    LOG_FILE="$LOG_DIR/$AGENT_NAME-$(date +%Y-%m-%d).log"
    ERROR_LOG="$LOG_DIR/$AGENT_NAME-errors-$(date +%Y-%m-%d).log"

    mkdir -p "$LOG_DIR"

    echo "[$(date -Iseconds)] Starting $AGENT_NAME: $*" >> "$LOG_FILE"

    "$@" 2> >(tee -a "$ERROR_LOG" >&2) | tee -a "$LOG_FILE"
    EXIT_CODE=$?

    echo "[$(date -Iseconds)] $AGENT_NAME exited with code $EXIT_CODE" >> "$LOG_FILE"

    ${lib.optionalString cfg.logging.notifyOnError ''
      if [ $EXIT_CODE -ne 0 ]; then
        notify-send -u critical "AI Agent Error" "$AGENT_NAME failed with exit code $EXIT_CODE"
      fi
    ''}

    exit $EXIT_CODE
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
