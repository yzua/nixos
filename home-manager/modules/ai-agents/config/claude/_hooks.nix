# Lifecycle hook configuration for Claude Code — aggregates per-stage hook modules.

let
  helpers = import ./_hooks-helpers.nix;
  inherit (helpers)
    mkFormatterHook
    mkBashHook
    mkPassthroughHook
    formatterRegistry
    ;

  preToolUse = import ./_hooks-pre-tool-use.nix { inherit mkBashHook; };
  postToolUse = import ./_hooks-post-tool-use.nix { inherit mkFormatterHook formatterRegistry; };
  session = import ./_hooks-session.nix { inherit mkPassthroughHook; };
in
preToolUse // postToolUse // session
