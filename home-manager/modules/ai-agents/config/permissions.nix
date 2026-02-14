# Claude Code permissions, lifecycle hooks, and extra settings.
{ config, constants, ... }:

{
  programs.aiAgents = {
    claude = {
      enable = true;
      model = "opus";

      env = {
        EDITOR = "nvim";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        MAX_MCP_OUTPUT_TOKENS = "50000"; # Default 10k; raised for large codebases
        MCP_TIMEOUT = "30000"; # Default 10s; raised for npx cold starts
        ENABLE_TOOL_SEARCH = "auto:5"; # Auto-search when >5 tools match; faster with 12+ MCPs
      };

      permissions = {
        allow = [
          "Bash(git *)"
          "Bash(gh *)"
          "Bash(npm run *)"
          "Bash(npx *)"
          "Bash(pnpm *)"
          "Bash(bun *)"
          "Bash(just *)"
          "Bash(make *)"
          "Bash(cmake *)"
          "Bash(nix *)"
          "Bash(nh *)"
          "Bash(home-manager *)"
          "Bash(cargo *)"
          "Bash(rustfmt *)"
          "Bash(go *)"
          "Bash(gofmt *)"
          "Bash(zig *)"
          "Bash(python *)"
          "Bash(pip *)"
          "Bash(uv *)"
          "Bash(ruff *)"
          "Bash(biome *)"
          "Bash(prettier *)"
          "Bash(statix *)"
          "Bash(deadnix *)"
          "Bash(docker *)"
          "Bash(docker-compose *)"
          "Bash(systemctl --user *)"
          "Bash(tmux *)"
        ];
        deny = [
          "Bash(rm -rf /)"
          "Bash(rm -rf ~)"
          "Bash(rm -rf /*)"
          "Bash(> /dev/sda*)"
          "Bash(mkfs*)"
          "Bash(dd if=*)"
          "Read(.env)"
          "Read(.env.*)"
          "Read(./secrets/**)"
          "Read(.ssh/*)"
          "Read(**/id_rsa*)"
          "Read(**/id_ed25519*)"
        ];
      };

      hooks = {
        PreToolUse = [
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(rm -rf|DROP|DELETE FROM|truncate)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "⚠️  DESTRUCTIVE COMMAND DETECTED" >&2
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "git commit"'';
            hooks = [
              {
                type = "command";
                command = ''
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
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(npm run dev|pnpm( run)? dev|yarn dev|bun run dev)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "[Hook] BLOCKED: Dev server must run in tmux for log access" >&2
                  echo "[Hook] Use: tmux new-session -d -s dev \"npm run dev\"" >&2
                  echo "[Hook] Then: tmux attach -t dev" >&2
                  exit 1
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "(npm (install|test)|pnpm (install|test)|yarn (install|test)?|bun (install|test)|cargo build|make|docker|pytest|vitest|playwright)"'';
            hooks = [
              {
                type = "command";
                command = ''
                  if [ -z "$TMUX" ]; then
                    echo "[Hook] Consider running in tmux for session persistence" >&2
                    echo "[Hook] tmux new -s dev  |  tmux attach -t dev" >&2
                  fi
                  cat
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "git push"'';
            hooks = [
              {
                type = "command";
                command = ''
                  echo "[Hook] Review changes before push..." >&2
                  cat
                '';
              }
            ];
          }
        ];
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
        PostToolUseFailure = [
          {
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  TOOL=$(echo "$INPUT" | jq -r '.tool // "unknown"')
                  ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' | head -5)
                  echo "[Hook] Tool FAILED: $TOOL — $ERROR" >&2
                  echo "$INPUT"
                '';
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx|js|jsx|json|jsonc)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v biome >/dev/null 2>&1; then
                    biome check --write "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.rs$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v rustfmt >/dev/null 2>&1; then
                    rustfmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.zig$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v zig >/dev/null 2>&1; then
                    zig fmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.go$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v gofmt >/dev/null 2>&1; then
                    gofmt -w "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.nix$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v nixfmt >/dev/null 2>&1; then
                    nixfmt "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.py$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v ruff >/dev/null 2>&1; then
                    ruff format "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(yaml|yml|toml)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$file_path" ] && command -v prettier >/dev/null 2>&1; then
                    prettier --write "$file_path" 2>&1 | head -3 >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Bash" && tool_input.command matches "gh pr create"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  PR_URL=$(echo "$INPUT" | jq -r '.tool_output.output // ""' | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' || true)
                  if [ -n "$PR_URL" ]; then
                    echo "[Hook] PR created: $PR_URL" >&2
                  fi
                  echo "$INPUT"
                '';
              }
            ];
          }
          {
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx|js|jsx)$"'';
            hooks = [
              {
                type = "command";
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
            matcher = ''tool == "Edit" && tool_input.file_path matches "\\.(ts|tsx)$"'';
            hooks = [
              {
                type = "command";
                command = ''
                  INPUT=$(cat)
                  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
                  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
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
                    stop_reason: .stop_reason,
                    cwd: $cwd,
                    git_branch: $branch
                  }' > "$SESSION_DIR/last-session.json" 2>/dev/null || true
                  echo "$INPUT"
                '';
              }
            ];
          }
        ];
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
      };

      extraSettings = {
        cleanupPeriodDays = 14;
        respectGitignore = true;
        alwaysThinkingEnabled = true;
        showTurnDuration = true;
        spinnerTipsEnabled = true;
        autoUpdatesChannel = "latest";
        prefersReducedMotion = false;
        attribution = {
          commit = "";
          pr = "";
        };
      };
    };
  };
}
