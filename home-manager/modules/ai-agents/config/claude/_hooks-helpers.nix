# Shared hook constructors for Claude Code lifecycle hooks.

let
  formatterRegistry = import ../../helpers/_formatters.nix;

  mkCommandHook =
    {
      body,
      matcher ? null,
      extractCommand ? (matcher != null),
      runInBackground ? false,
      timeout ? null,
    }:
    let
      bgAttrs = if runInBackground then { run_in_background = true; } else { };
      toAttrs = if timeout != null then { inherit timeout; } else { };
      matcherAttrs = if matcher != null then { inherit matcher; } else { };
      commandPrefix =
        if extractCommand then
          ''
            INPUT=$(cat)
            COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
          ''
        else
          ''
            INPUT=$(cat)
          '';
    in
    matcherAttrs
    // {
      hooks = [
        (
          {
            type = "command";
            command = ''
              ${commandPrefix}
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
  inherit formatterRegistry mkCommandHook;

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

  # Legacy aliases — prefer mkCommandHook directly.
  mkBashHook = args: mkCommandHook (args // { matcher = args.matcher or "Bash"; });
  mkPassthroughHook =
    args:
    mkCommandHook (
      args
      // {
        matcher = null;
        extractCommand = false;
      }
    );
}
