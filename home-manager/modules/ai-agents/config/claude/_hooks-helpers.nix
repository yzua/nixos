# Shared hook constructors for Claude Code lifecycle hooks.

let
  formatterRegistry = import ../../helpers/_formatters.nix;
in
{
  inherit formatterRegistry;

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
                ${builtins.concatStringsSep "|" (map (e: "*.${e}") extensions)}) ;;
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

  mkPassthroughHook =
    {
      body,
      timeout ? null,
      runInBackground ? false,
    }:
    let
      bgAttrs = if runInBackground then { run_in_background = true; } else { };
      toAttrs = if timeout != null then { inherit timeout; } else { };
    in
    {
      hooks = [
        (
          {
            type = "command";
            command = ''
              INPUT=$(cat)
              ${body}
              echo "$INPUT"
            '';
          }
          // bgAttrs
          // toAttrs
        )
      ];
    };
}
