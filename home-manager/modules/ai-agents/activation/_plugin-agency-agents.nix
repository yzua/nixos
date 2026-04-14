# Agency-agents installation for Claude Code and OpenCode.

{
  cfg,
  pkgs,
  lib,
}:

{
  installAgencyAgents = lib.mkIf cfg.agencyAgents.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ -d "$HOME/.local/share/agency-agents/.git" ]]; then
        echo "📦 Updating agency-agents..."
        ${pkgs.git}/bin/git -C "$HOME/.local/share/agency-agents" pull --ff-only 2>/dev/null || true
      else
        echo "📦 Cloning agency-agents..."
        rm -rf "$HOME/.local/share/agency-agents"
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/msitarzewski/agency-agents.git "$HOME/.local/share/agency-agents" 2>/dev/null || true
      fi
      AGENCY_DIR="$HOME/.local/share/agency-agents"

      if [[ -d "$AGENCY_DIR" && "${if cfg.claude.enable then "1" else "0"}" == "1" ]]; then
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

      if [[ -d "$AGENCY_DIR" && "${if cfg.opencode.enable then "1" else "0"}" == "1" ]]; then
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
    ''
  );
}
