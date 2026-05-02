# Zsh Configuration

Zsh + Oh My Zsh with Starship prompt, privacy-filtered history, agent wrapper functions, and Carapace completions.

---

## Files

| File             | Purpose                                                                                             |
| ---------------- | --------------------------------------------------------------------------------------------------- |
| `default.nix`    | Import hub, `sessionPath` (cargo, composer, gem, uv), Docker env vars                               |
| `config.nix`     | Core zsh options: history, OMZ plugins, vi mode, setOptions (21 opts)                               |
| `aliases.nix`    | Shell aliases applied to both zsh and bash via local `mkShellAliasPrograms`                         |
| `functions.nix`  | `initContent`: sops secret loaders, AI agent wrappers, `aip` launcher, Zellij tab rename, LS_COLORS |
| `local-vars.nix` | `localVariables`: editor, pager, FZF commands, XDG cache paths, tool homes                          |

---

## Key Patterns

### Dual-shell aliases

`aliases.nix` defines a local `mkShellAliasPrograms` function that applies the same `shellAliases` attrset to both `programs.zsh` and `programs.bash`. Always add aliases to the shared attrset — never to only one shell.

### Agent wrapper functions (`functions.nix`)

Agent wrappers (`claude_glm`, `opencode_*`, etc.) are zsh functions that:

1. Load API keys from `/run/secrets/` via `_load_secret` (from `home-manager/_helpers/_secret-loader.nix`).
2. Rename the current Zellij tab with an agent icon.
3. Launch the agent with the correct environment variables.

OpenCode profile wrappers are auto-generated from `ai-agents/helpers/_opencode-profiles.nix`. To add a new profile, update that file — the zsh wrappers follow automatically.

### `aip` multi-pane launcher

`aip` generates a KDL layout file and launches multiple AI agents in Zellij panes. It handles prompt injection per agent family (positional for claude/codex, `--prompt` flag for opencode).

### Privacy history

`config.nix` filters 28+ patterns from history (tokens, passwords, API keys, SSH, sops commands). Add new sensitive patterns to `history.ignorePatterns`.

### Completions

Carapace handles completions (`enableCompletion = false` in zsh). Do not enable OMZ completions or `zsh-completions`.

---

## Gotchas

- `functions.nix` imports from `../../ai-agents/helpers/` — changes to agent helpers propagate here.
- PATH extensions for language tools (go/bin, .deno/bin) are in their respective `programming-languages/` modules, not in `default.nix`.
- `VISUAL` and `GIT_EDITOR` use `constants.editor` (currently `code`). `GIT_EDITOR` adds `--wait` for interactive git operations.
