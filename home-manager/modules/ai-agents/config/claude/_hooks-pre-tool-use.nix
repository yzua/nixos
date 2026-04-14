# PreToolUse hooks — destructive command blocking, pre-commit checks, dev server warnings.

{ mkBashHook }:

let
  destructiveRules = import ../../helpers/_destructive-rules.nix;
in
{
  PreToolUse = [
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq '(^|[[:space:]])(sudo[[:space:]]+)?(${destructiveRules.mkHookRegex destructiveRules.systemCommands})'; then
          echo "[Hook] BLOCKED: system-destructive command detected" >&2
          echo "[Hook] Run it manually outside Claude if you truly intend it." >&2
          exit 2
        fi

        if echo "$COMMAND" | grep -Eq '(^|[[:space:]])(DROP|DELETE FROM|truncate)([[:space:]]|$)'; then
          echo "[Hook] WARNING: destructive database command detected" >&2
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq 'git commit'; then
          if [ -f "justfile" ] && just --summary 2>/dev/null | grep -qw "lint"; then
            echo "🔍 Pre-commit: running just lint..." >&2
            just lint 2>&1 | tail -5 >&2
          elif [ -f ".pre-commit-config.yaml" ] && command -v pre-commit >/dev/null 2>&1; then
            echo "🔍 Pre-commit: running pre-commit..." >&2
            pre-commit run --all-files 2>&1 | tail -5 >&2
          elif [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
            echo "🔍 Pre-commit: running npm run lint..." >&2
            npm run lint 2>&1 | tail -5 >&2
          elif [ -f "Cargo.toml" ] && command -v cargo >/dev/null 2>&1; then
            echo "🔍 Pre-commit: running cargo check..." >&2
            cargo check 2>&1 | tail -5 >&2
          fi
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq '(npm run dev|pnpm( run)? dev|yarn dev|bun run dev)'; then
          echo "[Hook] Long-running dev server detected; tmux is recommended for log persistence" >&2
          echo "[Hook] Example: tmux new-session -d -s dev \"''${COMMAND}\"" >&2
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if [ -z "$TMUX" ] && echo "$COMMAND" | grep -Eq '(npm (install|test)|pnpm (install|test)|yarn (install|test)?|bun (install|test)|cargo (build|test|check)|make|docker|pytest|vitest|playwright|just (check|lint|format|home|nixos|all))'; then
          echo "[Hook] Consider running in tmux for session persistence" >&2
          echo "[Hook] tmux new -s dev  |  tmux attach -t dev" >&2
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq 'git push'; then
          echo "[Hook] Review changes before push..." >&2
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq '(${destructiveRules.mkHookRegex destructiveRules.gitCommands})'; then
          echo "[Hook] BLOCKED: destructive git command requires explicit manual execution" >&2
          echo "[Hook] Use safer alternatives (regular push, targeted restore, or new commit)." >&2
          exit 2
        fi
      '';
    })
  ];
}
