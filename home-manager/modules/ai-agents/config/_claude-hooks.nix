# Lifecycle hook configuration for Claude Code.
let
  mkFormatterHook =
    {
      tool,
      extensions,
      command,
    }:
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            if [ -n "$file_path" ] && command -v ${tool} >/dev/null 2>&1; then
              case "$file_path" in
                ${builtins.concatStringsSep "|" (map (e: "*.${e}") extensions)} ;;
                *) echo "$INPUT"; exit 0 ;;
              esac
              ${command} "$file_path" 2>&1 | head -3 >&2
            fi
            echo "$INPUT"
          '';
        }
      ];
    };

  mkBashHook =
    {
      body,
      matcher ? "Bash",
      runInBackground ? false,
      timeout ? null,
    }:
    let
      bgAttrs = if runInBackground then { run_in_background = true; } else { };
      toAttrs = if timeout != null then { inherit timeout; } else { };
    in
    {
      inherit matcher;
      hooks = [
        (
          {
            type = "command";
            command = ''
              INPUT=$(cat)
              COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
              ${body}
              echo "$INPUT"
            '';
          }
          // bgAttrs
          // toAttrs
        )
      ];
    };
in
{
  # --- PreToolUse Hooks ---
  PreToolUse = [
    (mkBashHook {
      body = ''
        if echo "$COMMAND" | grep -Eq '(rm -rf|DROP|DELETE FROM|truncate)'; then
          echo "⚠️  DESTRUCTIVE COMMAND DETECTED" >&2
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
          echo "[Hook] BLOCKED: Dev server must run in tmux for log access" >&2
          echo "[Hook] Use: tmux new-session -d -s dev \"npm run dev\"" >&2
          echo "[Hook] Then: tmux attach -t dev" >&2
          exit 2
        fi
      '';
    })
    (mkBashHook {
      body = ''
        if [ -z "$TMUX" ] && echo "$COMMAND" | grep -Eq '(npm (install|test)|pnpm (install|test)|yarn (install|test)?|bun (install|test)|cargo build|make|docker|pytest|vitest|playwright)'; then
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
        if echo "$COMMAND" | grep -Eq '(git push --force|git push -f|git reset --hard|git clean -fd)'; then
          echo "[Hook] BLOCKED: destructive git command requires explicit manual execution" >&2
          echo "[Hook] Use safer alternatives (regular push, targeted restore, or new commit)." >&2
          exit 2
        fi
      '';
    })
  ];

  # --- Notification Hooks ---
  Notification = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            msg=$(cat | jq -r '.message // "Needs your attention"')
            notify-send -i dialog-information "Claude Code" "$msg" 2>/dev/null || true
          '';
        }
      ];
    }
  ];

  # --- Stop Hooks ---
  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            reason=$(cat | jq -r '.stop_reason // "completed"')
            notify-send -i dialog-information "Claude Code" "Task $reason" 2>/dev/null || true
          '';
        }
      ];
    }
  ];

  # --- PostToolUseFailure Hooks ---
  PostToolUseFailure = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
            ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' | head -5)
            echo "[Hook] Tool FAILED: $TOOL — $ERROR" >&2
            echo "$INPUT"
          '';
        }
      ];
    }
  ];

  # --- PostToolUse Hooks (Auto-Format + Analysis) ---
  PostToolUse = [
    (mkFormatterHook {
      tool = "biome";
      extensions = [
        "js"
        "jsx"
        "ts"
        "tsx"
        "mjs"
        "cjs"
        "json"
        "jsonc"
        "css"
        "scss"
        "less"
        "graphql"
        "gql"
      ];
      command = "biome check --write";
    })
    (mkFormatterHook {
      tool = "rustfmt";
      extensions = [ "rs" ];
      command = "rustfmt";
    })
    (mkFormatterHook {
      tool = "zig";
      extensions = [
        "zig"
        "zon"
      ];
      command = "zig fmt";
    })
    (mkFormatterHook {
      tool = "gofmt";
      extensions = [ "go" ];
      command = "gofmt -w";
    })
    (mkFormatterHook {
      tool = "nixfmt";
      extensions = [ "nix" ];
      command = "nixfmt";
    })
    (mkFormatterHook {
      tool = "ruff";
      extensions = [
        "py"
        "pyi"
      ];
      command = "ruff format";
    })
    (mkFormatterHook {
      tool = "prettier";
      extensions = [
        "md"
        "mdx"
        "yaml"
        "yml"
        "html"
        "vue"
        "svelte"
        "astro"
      ];
      command = "prettier --write";
    })
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
            if echo "$COMMAND" | grep -Eq 'gh pr create'; then
              PR_URL=$(echo "$INPUT" | jq -r '(.tool_response.output // .tool_response.stdout // .tool_output.output // "")' | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' || true)
              if [ -n "$PR_URL" ]; then
                echo "[Hook] PR created: $PR_URL" >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          run_in_background = true;
          timeout = 20000;
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
              MATCHES=$(grep -n "console\.log" "$FILE_PATH" 2>/dev/null | head -5)
              if [ -n "$MATCHES" ]; then
                echo "[Hook] WARNING: console.log found in $FILE_PATH" >&2
                echo "$MATCHES" >&2
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = ''
            INPUT=$(cat)
            FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
            if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
              case "$FILE_PATH" in
                *.ts|*.tsx|*.mts|*.cts) ;;
                *) echo "$INPUT"; exit 0 ;;
              esac
              DIR=$(dirname "$FILE_PATH")
              while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
                DIR=$(dirname "$DIR")
              done
              if [ -f "$DIR/tsconfig.json" ]; then
                TSC_OUT=$(cd "$DIR" && npx tsc --noEmit --pretty false 2>&1 | grep "$FILE_PATH" | head -10) || true
                if [ -n "$TSC_OUT" ]; then
                  echo "[Hook] TypeScript errors:" >&2
                  echo "$TSC_OUT" >&2
                fi
              fi
            fi
            echo "$INPUT"
          '';
        }
      ];
    }
  ];

  # --- Session Lifecycle Hooks ---
  SessionStart = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            SESSION_DIR="$HOME/.claude/session-state"
            if [ -f "$SESSION_DIR/last-session.json" ]; then
              echo "[Hook] Loaded previous session context" >&2
              cat "$SESSION_DIR/last-session.json" >&2
            fi
            cat
          '';
        }
      ];
    }
  ];

  SessionEnd = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            SESSION_DIR="$HOME/.claude/session-state"
            mkdir -p "$SESSION_DIR"
            INPUT=$(cat)
            GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            echo "$INPUT" | jq --arg cwd "$PWD" --arg branch "$GIT_BRANCH" '{
              timestamp: now,
              reason: (.reason // .stop_reason // "other"),
              cwd: $cwd,
              git_branch: $branch
            }' > "$SESSION_DIR/last-session.json" 2>/dev/null || true
            echo "$INPUT"
          '';
        }
      ];
    }
  ];

  # --- PreCompact Hook ---
  PreCompact = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            SESSION_DIR="$HOME/.claude/session-state"
            mkdir -p "$SESSION_DIR"
            echo "[Hook] Saving state before compaction..." >&2
            date -Iseconds > "$SESSION_DIR/last-compact.txt"
            cat
          '';
        }
      ];
    }
  ];
}
