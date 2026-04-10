# Plugin installation — impeccable and agency-agents.

{
  cfg,
  config,
  pkgs,
  lib,
}:

let
  opencodeProfiles = import ../helpers/_opencode-profiles.nix { inherit config; };
  eccCfg = cfg.everythingClaudeCode;

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

  installEverythingClaudeCode = lib.mkIf eccCfg.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Keep ECC intentionally curated here instead of emulating upstream install.sh.
      # This repo wants declarative, low-risk agent assets without broad hooks,
      # MCP imports, or other impure setup side effects.
      ${mkGitClone {
        name = "everything-claude-code";
        url = "https://github.com/affaan-m/everything-claude-code.git";
        dir = "$HOME/.local/share/everything-claude-code";
        var = "ECC_DIR";
      }}

      copy_ecc_file() {
        local src="$1"
        local dst="$2"

        [[ -f "$src" ]] || return 0
        mkdir -p "$(dirname "$dst")"
        cp -f "$src" "$dst"
      }

      copy_ecc_dir() {
        local src="$1"
        local dst="$2"

        [[ -d "$src" ]] || return 0
        rm -rf "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
      }

      if [[ -d "$ECC_DIR" && "${if cfg.claude.enable then "1" else "0"}" == "1" && "${
        if eccCfg.claude.enable then "1" else "0"
      }" == "1" ]]; then
        ${lib.optionalString eccCfg.claude.installSkillPack ''
          copy_ecc_dir "$ECC_DIR/.claude/skills/everything-claude-code" "$HOME/.claude/skills/everything-claude-code"
        ''}
        ${lib.concatMapStringsSep "\n" (name: ''
          copy_ecc_file "$ECC_DIR/.claude/commands/${name}.md" "$HOME/.claude/commands/ecc-${name}.md"
        '') eccCfg.claude.commands}
        echo "✓ Everything Claude Code installed for Claude Code"
      fi

      if [[ -d "$ECC_DIR" && "${if cfg.codex.enable then "1" else "0"}" == "1" && "${
        if eccCfg.codex.enable then "1" else "0"
      }" == "1" ]]; then
        mkdir -p "$HOME/.codex/agents"
        ${lib.concatMapStringsSep "\n" (name: ''
          copy_ecc_file "$ECC_DIR/.codex/agents/${name}.toml" "$HOME/.codex/agents/ecc-${name}.toml"
        '') eccCfg.codex.agents}
        echo "✓ Everything Claude Code installed for Codex"
      fi

      if [[ -d "$ECC_DIR" && "${if cfg.opencode.enable then "1" else "0"}" == "1" && "${
        if eccCfg.opencode.enable then "1" else "0"
      }" == "1" ]]; then
        for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfiles.names)}; do
          commands_dir="$HOME/.config/$profile/commands"
          mkdir -p "$commands_dir"
          ${lib.concatMapStringsSep "\n" (name: ''
            copy_ecc_file "$ECC_DIR/.opencode/commands/${name}.md" "$commands_dir/ecc-${name}.md"
          '') eccCfg.opencode.commands}
          ${lib.optionalString eccCfg.opencode.installInstructions ''
            copy_ecc_file "$ECC_DIR/.opencode/instructions/INSTRUCTIONS.md" "$HOME/.config/$profile/instructions/everything-claude-code.md"
          ''}
        done
        echo "✓ Everything Claude Code installed for OpenCode"
      fi
    ''
  );

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
            implementation-engineer.md|protocol-triage.md|security-reviewer.md|static-recon.md|nix-evaluator.md|lint-fixer.md|release-notes.md)
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
