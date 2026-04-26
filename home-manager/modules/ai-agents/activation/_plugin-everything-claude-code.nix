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
  gitCloneUpdate = import ../helpers/_git-clone-update.nix { inherit pkgs; };
in

{
  installEverythingClaudeCode = lib.mkIf eccCfg.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Keep ECC intentionally curated here instead of emulating upstream install.sh.
      # This repo wants declarative, low-risk agent assets without broad hooks,
      # MCP imports, or other impure setup side effects.
      ${gitCloneUpdate {
        name = "everything-claude-code";
        url = "https://github.com/affaan-m/everything-claude-code.git";
      }}
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

      ${lib.optionalString (cfg.claude.enable && eccCfg.claude.enable) ''
        if [[ -d "$ECC_DIR" ]]; then
          ${lib.optionalString eccCfg.claude.installSkillPack ''
            copy_ecc_dir "$ECC_DIR/.claude/skills/everything-claude-code" "$HOME/.claude/skills/everything-claude-code"
          ''}
          ${lib.concatMapStringsSep "\n" (name: ''
            copy_ecc_file "$ECC_DIR/.claude/commands/${name}.md" "$HOME/.claude/commands/ecc-${name}.md"
          '') eccCfg.claude.commands}
          echo "✓ Everything Claude Code installed for Claude Code"
        fi
      ''}

      ${lib.optionalString (cfg.codex.enable && eccCfg.codex.enable) ''
        if [[ -d "$ECC_DIR" ]]; then
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
      ''}

      ${lib.optionalString (cfg.opencode.enable && eccCfg.opencode.enable) ''
        if [[ -d "$ECC_DIR" ]]; then
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
      ''}
    ''
  );
}
