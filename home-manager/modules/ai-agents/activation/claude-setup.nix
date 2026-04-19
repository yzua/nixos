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
    jq = "${pkgs.jq}/bin/jq";
    claudeSettingsFile = pkgs.writeText "claude-settings.json" (toJSON claudeSettings);
    claudeMcpFile = pkgs.writeText "claude-mcp.json" (toJSON {
      mcpServers = claudeMcpServers;
    });
    claudeInstructionsFile = pkgs.writeText "CLAUDE.md" cfg.globalInstructions;

    # Merge a Nix-generated JSON file into an existing target.
    # If the target exists as a regular file, deep-merge using jq;
    # otherwise, copy the source file fresh.
    mergeJsonFile = target: source: filter: ''
      if [[ -f "${target}" ]] && [[ ! -L "${target}" ]]; then
        ${jq} -s '${filter}' "${target}" "${source}" > "${target}.tmp"
        mv "${target}.tmp" "${target}"
      else
        rm -f "${target}"
        cp "${source}" "${target}"
        chmod 644 "${target}"
      fi
    '';
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.claude"

    ${mergeJsonFile "$HOME/.claude/settings.json" claudeSettingsFile ".[0] * .[1]"}
    echo "✓ Claude settings.json configured"

    ${mergeJsonFile "$HOME/.mcp.json" claudeMcpFile
      "(.[1].mcpServers) as $mcpServers | .[0] * .[1] | .mcpServers = $mcpServers"
    }
    echo "✓ Claude .mcp.json configured"

    ${lib.optionalString (cfg.globalInstructions != "") ''
      CLAUDE_MD="$HOME/.claude/CLAUDE.md"
      cp "${claudeInstructionsFile}" "$CLAUDE_MD"
      echo "✓ Claude CLAUDE.md configured"
    ''}
  ''
)
