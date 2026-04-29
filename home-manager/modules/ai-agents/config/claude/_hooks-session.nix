# Session lifecycle hooks — notifications, permissions, failures, stop.

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

  SubagentStop = [
    (mkPassthroughHook {
      body = ''
        AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .agent // "unknown"')
        STATUS=$(echo "$INPUT" | jq -r '.status // .stop_reason // "completed"')
        echo "[Hook] Subagent finished: $AGENT_NAME ($STATUS)" >&2
      '';
    })
  ];
}
