# Cleanup for disabled Everything Claude Code.
#
# Removes all ECC assets unconditionally across all agent profiles when the
# top-level `everythingClaudeCode.enable` is false, regardless of per-agent
# toggles (claude/codex/opencode). This is intentional: cleanup must be thorough
# to avoid orphaned files from a previous activation where ECC was enabled.

{
  cfg,
  lib,
  opencodeProfileNames,
}:

let
  eccCfg = cfg.everythingClaudeCode;
in

{
  cleanupDisabledEverythingClaudeCode = lib.mkIf (!eccCfg.enable) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf "$HOME/.claude/skills/everything-claude-code"
      rm -f "$HOME/.claude/commands/ecc-"*.md 2>/dev/null || true
      rm -f "$HOME/.codex/agents/ecc-"*.toml 2>/dev/null || true
      for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfileNames)}; do
        rm -f "$HOME/.config/$profile/commands/ecc-"*.md 2>/dev/null || true
        rm -f "$HOME/.config/$profile/instructions/everything-claude-code.md" 2>/dev/null || true
      done
      rm -rf "$HOME/.local/share/everything-claude-code"
    ''
  );
}
