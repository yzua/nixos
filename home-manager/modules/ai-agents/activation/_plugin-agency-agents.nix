# Agency-agents installation for Claude Code and OpenCode.

{
  cfg,
  pkgs,
  lib,
}:

let
  gitCloneUpdate = import ../helpers/_git-clone-update.nix { inherit pkgs; };
in

{
  installAgencyAgents = lib.mkIf cfg.agencyAgents.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${gitCloneUpdate {
        name = "agency-agents";
        url = "https://github.com/msitarzewski/agency-agents.git";
      }}
      AGENCY_DIR="$HOME/.local/share/agency-agents"

      ${lib.optionalString cfg.claude.enable ''
        if [[ -d "$AGENCY_DIR" ]]; then
          mkdir -p "$HOME/.claude/agents"
          for division in \
            design \
            engineering \
            game-development \
            marketing \
            paid-media \
            sales \
            product \
            project-management \
            testing \
            support \
            spatial-computing \
            specialized
          do
            if [[ -d "$AGENCY_DIR/$division" ]]; then
              cp -f "$AGENCY_DIR/$division"/*.md "$HOME/.claude/agents/" 2>/dev/null || true
            fi
          done
          echo "✓ agency-agents installed for Claude Code"
        fi
      ''}

      ${lib.optionalString cfg.opencode.enable ''
        if [[ -d "$AGENCY_DIR" ]]; then
          if [[ -x "$AGENCY_DIR/scripts/convert.sh" ]]; then
            echo "📦 Converting agency-agents for OpenCode..."
            (
              cd "$AGENCY_DIR"
              ./scripts/convert.sh --tool opencode
            ) >/dev/null 2>&1 || true
          fi

          if [[ -d "$AGENCY_DIR/integrations/opencode/agents" ]]; then
            mkdir -p "$HOME/.config/opencode/agents"
            cp -f "$AGENCY_DIR/integrations/opencode/agents"/*.md "$HOME/.config/opencode/agents/" 2>/dev/null || true
            echo "✓ agency-agents installed for OpenCode"
          fi
        fi
      ''}
    ''
  );
}
