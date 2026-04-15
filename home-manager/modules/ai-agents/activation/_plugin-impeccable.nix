# Impeccable skill pack installation for Claude Code and OpenCode.

{
  cfg,
  config,
  pkgs,
  lib,
}:

let
  opencodeProfiles = import ../helpers/_opencode-profiles.nix { inherit config; };
  gitCloneUpdate = import ../helpers/_git-clone-update.nix { inherit pkgs; };
in

{
  installImpeccable = lib.mkIf cfg.impeccable.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${gitCloneUpdate {
        name = "impeccable";
        url = "https://github.com/pbakaus/impeccable.git";
      }}
      IMPECCABLE_DIR="$HOME/.local/share/impeccable"

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
}
