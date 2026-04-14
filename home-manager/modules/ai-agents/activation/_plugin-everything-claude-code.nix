# Everything Claude Code asset installation for Claude Code, Codex, and OpenCode.

{
  cfg,
  config,
  pkgs,
  lib,
}:

let
  eccCfg = cfg.everythingClaudeCode;
  opencodeProfiles = import ../helpers/_opencode-profiles.nix { inherit config; };
in

{
  installEverythingClaudeCode = lib.mkIf eccCfg.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Keep ECC intentionally curated here instead of emulating upstream install.sh.
      # This repo wants declarative, low-risk agent assets without broad hooks,
      # MCP imports, or other impure setup side effects.
      if [[ -d "$HOME/.local/share/everything-claude-code/.git" ]]; then
        echo "📦 Updating everything-claude-code..."
        ${pkgs.git}/bin/git -C "$HOME/.local/share/everything-claude-code" pull --ff-only 2>/dev/null || true
      else
        echo "📦 Cloning everything-claude-code..."
        rm -rf "$HOME/.local/share/everything-claude-code"
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git "$HOME/.local/share/everything-claude-code" 2>/dev/null || true
      fi
      ECC_DIR="$HOME/.local/share/everything-claude-code"

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
          if [[ -f "$HOME/.codex/agents/ecc-${name}.toml" ]] && ! ${pkgs.gnugrep}/bin/grep -Eq '^name\s*=\s*".+"' "$HOME/.codex/agents/ecc-${name}.toml"; then
            tmp_file="$HOME/.codex/agents/.ecc-${name}.toml.tmp"
            {
              printf 'name = "ecc-${name}"\n'
              cat "$HOME/.codex/agents/ecc-${name}.toml"
            } > "$tmp_file"
            mv "$tmp_file" "$HOME/.codex/agents/ecc-${name}.toml"
          fi
          if [[ -f "$HOME/.codex/agents/ecc-${name}.toml" ]] && ! ${pkgs.gnugrep}/bin/grep -Eq '^description\s*=\s*".+"' "$HOME/.codex/agents/ecc-${name}.toml"; then
            tmp_file="$HOME/.codex/agents/.ecc-${name}.toml.tmp"
            {
              printf 'description = "Everything Claude Code imported agent: ${name}"\n'
              cat "$HOME/.codex/agents/ecc-${name}.toml"
            } > "$tmp_file"
            mv "$tmp_file" "$HOME/.codex/agents/ecc-${name}.toml"
          fi
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
}
