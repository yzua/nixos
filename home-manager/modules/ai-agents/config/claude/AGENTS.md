# Claude Code Configuration

Permissions, lifecycle hooks, and settings for Claude Code. Outputs a structured attrset consumed by `programs.aiAgents.claude` in the parent config hub.

---

## Files

| File                     | Purpose                                                                |
| ------------------------ | ---------------------------------------------------------------------- |
| `default.nix`            | Import hub: model, env, permissions, hooks, extraSettings              |
| `_permission-rules.nix`  | `allow` and `deny` patterns for Bash commands and file reads           |
| `_hooks.nix`             | Aggregation layer: imports helpers and merges per-stage hook modules   |
| `_hooks-helpers.nix`     | Shared hook constructors: `mkCommandHook`, `mkFormatterHook`, `mkPassthroughHook` |
| `_hooks-pre-tool-use.nix`  | PreToolUse hooks: destructive command blocking, pre-commit lint, dev server warnings |
| `_hooks-post-tool-use.nix` | PostToolUse hooks: auto-formatting (from `formatterRegistry`), console.log warnings, TypeScript checking |
| `_hooks-session.nix`     | Session hooks: notifications, session state persistence, compaction, permission logging |

---

## Hook Architecture

Hooks follow a layered construction pattern:

1. `_hooks-helpers.nix` provides constructors (`mkCommandHook`, `mkFormatterHook`, `mkPassthroughHook`).
2. Per-stage modules (`_hooks-pre-tool-use.nix`, `_hooks-post-tool-use.nix`, `_hooks-session.nix`) call these constructors with stage-specific matchers and bodies.
3. `_hooks.nix` merges all stages into a single attrset.

### Hook types

- **`mkBashHook`**: Matches `Bash` tool use. Extracts `COMMAND` from stdin JSON. Used for safety checks.
- **`mkFormatterHook`**: Matches `Edit|Write`. Runs a formatter on matching file extensions. Sourced from `../../helpers/_formatters.nix`.
- **`mkPassthroughHook`**: No matcher. Receives raw `INPUT` JSON. Used for session lifecycle events.

---

## Permission Rules

`_permission-rules.nix` defines two lists:

- **`allow`**: Safe commands (git, npm, nix, go, docker, systemctl --user, etc.)
- **`deny`**: Destructive system commands (from `../../helpers/_destructive-rules.nix`) + sensitive file read patterns (`.env`, `.ssh/*`, secrets)

To allow a new tool: add `Bash(toolname *)` to the `allow` list.

---

## Adding a Hook

1. Identify the stage (PreToolUse, PostToolUse, or session event).
2. Use the appropriate constructor from `_hooks-helpers.nix`.
3. Add the hook to the correct per-stage module file.
4. Hooks run in list order within each stage.

---

## Gotchas

- `extraSettings.defaultMode = "bypassPermissions"` means Claude runs without interactive permission prompts. The deny rules in `_permission-rules.nix` and the PreToolUse hooks are the safety net.
- `_hooks-post-tool-use.nix` imports `formatterRegistry` from `../../helpers/_formatters.nix` — formatter changes propagate here.
- PreToolUse hooks use `exit 2` to block a tool call. Non-zero exit is the only way to block; `exit 0` passes through.
