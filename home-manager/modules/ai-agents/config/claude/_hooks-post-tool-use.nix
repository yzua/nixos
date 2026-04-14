# PostToolUse hooks — auto-formatting, PR detection, console.log warnings, TypeScript checking.

{ mkFormatterHook, formatterRegistry }:

{
  PostToolUse = formatterRegistry.mkClaudeFormatterHooks mkFormatterHook ++ [
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
}
