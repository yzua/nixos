# Claude configuration activation — generates ~/.claude/settings.json and ~/.mcp.json.

{
  cfg,
  pkgs,
  lib,
  toJSON,
  claudeSettings,
  claudeMcpServers,
}:
lib.mkIf cfg.claude.enable (
  let
    claudeSettingsFile = pkgs.writeText "claude-settings.json" (toJSON claudeSettings);
    claudeMcpFile = pkgs.writeText "claude-mcp.json" (toJSON {
      mcpServers = claudeMcpServers;
    });
    claudeInstructionsFile = pkgs.writeText "CLAUDE.md" cfg.globalInstructions;
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.claude"

    CLAUDE_SETTINGS="$HOME/.claude/settings.json"

    if [[ -f "$CLAUDE_SETTINGS" ]] && [[ ! -L "$CLAUDE_SETTINGS" ]]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "${claudeSettingsFile}" > "$CLAUDE_SETTINGS.tmp"
      mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
    else
      rm -f "$CLAUDE_SETTINGS"
      cp "${claudeSettingsFile}" "$CLAUDE_SETTINGS"
      chmod 644 "$CLAUDE_SETTINGS"
    fi
    echo "✓ Claude settings.json configured"

    CLAUDE_MCP="$HOME/.mcp.json"

    if [[ -f "$CLAUDE_MCP" ]] && [[ ! -L "$CLAUDE_MCP" ]]; then
      ${pkgs.jq}/bin/jq -s '(.[1].mcpServers) as $mcpServers | .[0] * .[1] | .mcpServers = $mcpServers' "$CLAUDE_MCP" "${claudeMcpFile}" > "$CLAUDE_MCP.tmp"
      mv "$CLAUDE_MCP.tmp" "$CLAUDE_MCP"
    else
      rm -f "$CLAUDE_MCP"
      cp "${claudeMcpFile}" "$CLAUDE_MCP"
      chmod 644 "$CLAUDE_MCP"
    fi
    echo "✓ Claude .mcp.json configured"

    ${lib.optionalString (cfg.globalInstructions != "") ''
        CLAUDE_MD="$HOME/.claude/CLAUDE.md"
        cp "${claudeInstructionsFile}" "$CLAUDE_MD"
        echo "✓ Claude CLAUDE.md configured"
    ''}
  ''
)
