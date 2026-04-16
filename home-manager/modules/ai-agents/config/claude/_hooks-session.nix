# Session lifecycle hooks — start, end, compact, notifications, permissions, failures.

{ mkPassthroughHook }:

{
  PermissionRequest = [
    (mkPassthroughHook {
      body = ''
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        DECISION_HINT=$(echo "$INPUT" | jq -r '.permission_mode // .mode // "unknown"')
        echo "[Hook] Permission request: $TOOL_NAME (mode: $DECISION_HINT)" >&2
      '';
    })
  ];

  PermissionDenied = [
    (mkPassthroughHook {
      body = ''
        TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        echo "[Hook] Permission denied: $TOOL_NAME" >&2
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

  StopFailure = [
    {
      hooks = [
        {
          type = "command";
          command = ''
            reason=$(cat | jq -r '.stop_reason // .reason // "failed"')
            notify-send -i dialog-error "Claude Code" "Task $reason" 2>/dev/null || true
          '';
        }
      ];
    }
  ];

  # --- PostToolUseFailure Hooks ---
  PostToolUseFailure = [
    (mkPassthroughHook {
      body = ''
        TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // "unknown"')
        ERROR=$(echo "$INPUT" | jq -r '.error // "no error"' | head -5)
        echo "[Hook] Tool FAILED: $TOOL — $ERROR" >&2
      '';
    })
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
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo "$INPUT" | jq --arg cwd "$PWD" --arg branch "$GIT_BRANCH" '{
          timestamp: now,
          reason: (.reason // .stop_reason // "other"),
          cwd: $cwd,
          git_branch: $branch
        }' > "$SESSION_DIR/last-session.json" 2>/dev/null || true
      '';
    })
  ];

  SubagentStop = [
    (mkPassthroughHook {
      body = ''
        AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .agent // "unknown"')
        STATUS=$(echo "$INPUT" | jq -r '.status // .stop_reason // "completed"')
        echo "[Hook] Subagent finished: $AGENT_NAME ($STATUS)" >&2
      '';
    })
  ];

  # --- PreCompact Hook ---
  PreCompact = [
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        echo "[Hook] Saving state before compaction..." >&2
        date -Iseconds > "$SESSION_DIR/last-compact.txt"
      '';
    })
  ];

  PostCompact = [
    (mkPassthroughHook {
      body = ''
        SESSION_DIR="$HOME/.claude/session-state"
        mkdir -p "$SESSION_DIR"
        date -Iseconds > "$SESSION_DIR/last-post-compact.txt"
        echo "[Hook] Context compaction completed" >&2
      '';
    })
  ];
}
