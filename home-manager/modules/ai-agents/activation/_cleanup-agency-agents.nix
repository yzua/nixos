# Cleanup for disabled agency-agents.

{
  cfg,
  lib,
}:

{
  cleanupDisabledAgencyAgents = lib.mkIf (!cfg.agencyAgents.enable) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      AGENCY_DIR="$HOME/.local/share/agency-agents"
      CLAUDE_AGENTS_DIR="$HOME/.claude/agents"

      if [[ -d "$AGENCY_DIR" && -d "$CLAUDE_AGENTS_DIR" ]]; then
        while IFS= read -r agency_agent; do
          [[ -n "$agency_agent" ]] || continue
          rm -f "$CLAUDE_AGENTS_DIR/$agency_agent"
        done < <(find "$AGENCY_DIR" -mindepth 2 -maxdepth 2 -type f -name '*.md' -printf '%f\n' 2>/dev/null | sort -u)
        echo "✓ Removed disabled agency-agents from Claude Code"
      fi

      if [[ -d "$CLAUDE_AGENTS_DIR" ]]; then
        for agent_file in "$CLAUDE_AGENTS_DIR"/*.md; do
          [[ -e "$agent_file" ]] || continue
          case "$(basename "$agent_file")" in
            implementation-engineer.md|protocol-triage.md|security-reviewer.md|static-recon.md|release-notes.md)
              ;;
            *)
              rm -f "$agent_file"
              ;;
          esac
        done
        echo "✓ Curated Claude Code agents for coding and RE"
      fi

      if [[ -d "$HOME/.config/opencode/agents" ]]; then
        rm -f "$HOME/.config/opencode/agents/"*.md 2>/dev/null || true
      fi
    ''
  );
}
