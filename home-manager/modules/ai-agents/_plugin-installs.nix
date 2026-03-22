# Claude plugin installation — oh-my-claudecode and everything-claude-code.
{
  cfg,
  config,
  pkgs,
  lib,
}:

let
  opencodeProfiles = import ./_opencode-profiles.nix { inherit config; };

  mkGitClone =
    {
      name,
      url,
      dir,
      var ? null,
    }:
    (lib.optionalString (var != null) ''${var}="${dir}"'')
    + ''

      if [[ -d "${dir}/.git" ]]; then
        echo "📦 Updating ${name}..."
        ${pkgs.git}/bin/git -C "${dir}" pull --ff-only 2>/dev/null || true
      else
        echo "📦 Cloning ${name}..."
        rm -rf "${dir}"
        ${pkgs.git}/bin/git clone --depth 1 ${url} "${dir}" 2>/dev/null || true
      fi
    '';
in
{
  installImpeccable = lib.mkIf cfg.impeccable.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${mkGitClone {
        name = "impeccable";
        url = "https://github.com/pbakaus/impeccable.git";
        dir = "$HOME/.local/share/impeccable";
        var = "IMPECCABLE_DIR";
      }}

      if [[ -d "$IMPECCABLE_DIR" ]]; then
        echo "📦 Building impeccable bundles..."
        (
          cd "$IMPECCABLE_DIR"
          ${pkgs.bun}/bin/bun install --frozen-lockfile >/dev/null 2>&1 || ${pkgs.bun}/bin/bun install >/dev/null 2>&1
          ${pkgs.bun}/bin/bun run build >/dev/null 2>&1
        ) || true
      fi

      if [[ -d "$IMPECCABLE_DIR/dist/claude-code/.claude/skills" && "${
        if cfg.claude.enable then "1" else "0"
      }" == "1" ]]; then
        mkdir -p "$HOME/.claude/skills"
        for src in "$IMPECCABLE_DIR"/dist/claude-code/.claude/skills/*; do
          [[ -e "$src" ]] || continue
          name="$(basename "$src")"
          dst="$HOME/.claude/skills/$name"
          if [[ -e "$dst" && ! -d "$dst" ]]; then
            rm -f "$dst"
          fi
          cp -r "$src" "$dst" 2>/dev/null || true
        done
        echo "✓ impeccable installed for Claude Code"
      fi

      if [[ -d "$IMPECCABLE_DIR/dist/opencode/.opencode/skills" && "${
        if cfg.opencode.enable then "1" else "0"
      }" == "1" ]]; then
        for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfiles.names)}; do
          skills_dir="$HOME/.config/$profile/skills"
          mkdir -p "$skills_dir"
          for src in "$IMPECCABLE_DIR"/dist/opencode/.opencode/skills/*; do
            [[ -e "$src" ]] || continue
            name="$(basename "$src")"
            dst="$skills_dir/$name"
            if [[ -e "$dst" && ! -d "$dst" ]]; then
              rm -f "$dst"
            fi
            cp -r "$src" "$dst" 2>/dev/null || true
          done
        done
        echo "✓ impeccable installed for OpenCode"
      fi
    ''
  );

  installAgencyAgents = lib.mkIf cfg.agencyAgents.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${mkGitClone {
        name = "agency-agents";
        url = "https://github.com/msitarzewski/agency-agents.git";
        dir = "$HOME/.local/share/agency-agents";
        var = "AGENCY_DIR";
      }}

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

  installOhMyClaudeCode = lib.mkIf cfg.claude.enable (
    lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
      if command -v claude &> /dev/null; then
        if ! claude plugin marketplace list 2>/dev/null | grep -q "omc"; then
          echo "📦 Adding oh-my-claudecode marketplace..."
          claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode 2>/dev/null || true
        fi

        if ! claude plugin list 2>/dev/null | grep -q "oh-my-claudecode"; then
          echo "📦 Installing oh-my-claudecode plugin..."
          claude plugin install oh-my-claudecode@omc 2>/dev/null || true
        fi
        echo "✓ oh-my-claudecode ready"
      fi
    ''
  );

  installEverythingClaudeCode = lib.mkIf cfg.claude.enable (
    lib.hm.dag.entryAfter [ "setupClaudeConfig" ] ''
      ECC_DIR="$HOME/.local/share/everything-claude-code"

      if command -v claude &> /dev/null; then
        ${mkGitClone {
          name = "everything-claude-code";
          url = "https://github.com/affaan-m/everything-claude-code.git";
          dir = "$ECC_DIR";
        }}

        if ! claude plugin marketplace list 2>/dev/null | grep -q "everything-claude-code"; then
          echo "📦 Adding everything-claude-code marketplace..."
          claude plugin marketplace add affaan-m/everything-claude-code 2>/dev/null || true
        fi

        if ! claude plugin list 2>/dev/null | grep -q "everything-claude-code"; then
          echo "📦 Installing everything-claude-code plugin..."
          claude plugin install everything-claude-code@everything-claude-code 2>/dev/null || true
        fi

        if [[ -d "$ECC_DIR/rules" ]]; then
          mkdir -p "$HOME/.claude/rules"
          if [[ -d "$ECC_DIR/rules/common" ]]; then
            cp -r "$ECC_DIR/rules/common/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/typescript" ]]; then
            cp -r "$ECC_DIR/rules/typescript/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/python" ]]; then
            cp -r "$ECC_DIR/rules/python/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          if [[ -d "$ECC_DIR/rules/golang" ]]; then
            cp -r "$ECC_DIR/rules/golang/"* "$HOME/.claude/rules/" 2>/dev/null || true
          fi
          echo "✓ Installed ECC rules (common + typescript + python + golang)"
        fi

        echo "✓ everything-claude-code ready"
      fi
    ''
  );
}
