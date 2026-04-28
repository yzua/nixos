# AI Agents — Activation

Home Manager activation scripts that run after `writeBoundary`. Handle late-stage operations that cannot be pure Nix: secret injection, config file generation with merge semantics, skills bootstrap with state caching, and plugin installation with cleanup on disable.

Parent: `home-manager/modules/ai-agents/AGENTS.md`

---

## Files

| File                                  | Purpose                                                                                  |
| ------------------------------------- | ---------------------------------------------------------------------------------------- |
| `default.nix`                         | Aggregation hub: wires all activation DAG entries into `home.activation`                 |
| `secrets.nix`                         | Secret patching: injects Z.AI, OpenRouter, Context7, GitHub tokens via jq/sed            |
| `claude-setup.nix`                    | Generates `~/.claude/settings.json` and `~/.mcp.json` with jq merge for existing configs |
| `codex-setup.nix`                     | Generates `~/.codex/config.toml` with personality, model, MCP, profiles, agents          |
| `skills.nix`                          | Skills CLI bootstrap with retry, state caching (SHA256 skip), Claude-to-Codex mirroring  |
| `plugins.nix`                         | Plugin aggregation: imports impeccable, agency-agents, ECC installers + cleanup          |
| `_plugin-impeccable.nix`              | Impeccable skill pack: git clone, bun build, copy to Claude/OpenCode skill dirs          |
| `_plugin-agency-agents.nix`           | Agency agents: clone and copy division agent `.md` files to agent dirs                   |
| `_plugin-everything-claude-code.nix`  | ECC: clone, curated copy of skills/commands/agents to all profiles                       |
| `_cleanup-agency-agents.nix`          | Removes agency-agent files when disabled, preserves curated agents                       |
| `_cleanup-everything-claude-code.nix` | Removes ECC files from Claude/Codex/OpenCode when disabled                               |
| `pi-setup.nix`                        | Pi CLI setup: installs npm package, creates config/extension/session directories         |

---

## Conventions

- **DAG ordering**: All entries use `lib.hm.dag.entryAfter [ "writeBoundary" ... ]`. `secrets.nix` also depends on `"linkGeneration"`, `"setupCodexConfig"`, `"setupClaudeConfig"`.
- **Real files, not symlinks**: `claude-setup.nix` checks `[[ ! -L ]]` and does jq merge for existing real files.
- **Best-effort with warnings**: `skills.nix` logs failures as warnings and continues activation.
- **State caching**: `skills.nix` computes SHA256 of desired skill state and skips reinstall if unchanged.
- **Curated vs. installed**: cleanup files preserve agents defined in `_file-templates.nix` while removing plugin-installed files.

---

## Gotchas

- `secrets.nix` placeholder strings (`__GITHUB_TOKEN_PLACEHOLDER__`, etc.) must match exactly what `files.nix` and model configs write.
- `skills.nix` intentionally disables `~/.agents/skills` (moves to `.disabled-by-home-manager`) to prevent OpenCode duplicate-skill spam.
- `codex-setup.nix` deletes non-ECC custom agents on each activation (`find ... ! -name 'ecc-*.toml' -delete`).
- `claude-setup.nix` writes CLAUDE.md from `cfg.globalInstructions` — same content injected into Codex and OpenCode via their own paths.
- Plugin/cleanup files use relative imports (`../helpers/`) that assume stable directory structure.

---

## Dependencies

- `../helpers/_mcp-transforms.nix`, `../helpers/_settings-builders.nix`, `../helpers/_opencode-profiles.nix`, `../helpers/_zai-filters.nix`, `../helpers/_file-templates.nix`, `../helpers/_git-clone-update.nix`
- `constants` from flake for Z.AI URL resolution
