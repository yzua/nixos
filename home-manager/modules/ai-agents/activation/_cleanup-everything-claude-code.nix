# Cleanup for disabled Everything Claude Code.

{
  cfg,
  config,
  lib,
}:

let
  eccCfg = cfg.everythingClaudeCode;
  opencodeProfiles = import ../helpers/_opencode-profiles.nix { inherit config; };
in

{
  cleanupDisabledEverythingClaudeCode = lib.mkIf (!eccCfg.enable) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf "$HOME/.claude/skills/everything-claude-code"
      rm -f "$HOME/.claude/commands/ecc-"*.md 2>/dev/null || true
      rm -f "$HOME/.codex/agents/ecc-"*.toml 2>/dev/null || true
      for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfiles.names)}; do
        rm -f "$HOME/.config/$profile/commands/ecc-"*.md 2>/dev/null || true
        rm -f "$HOME/.config/$profile/instructions/everything-claude-code.md" 2>/dev/null || true
      done
      rm -rf "$HOME/.local/share/everything-claude-code"
    ''
  );
}
