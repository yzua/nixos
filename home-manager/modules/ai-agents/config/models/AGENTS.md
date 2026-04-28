# AI Agents — Model Configs

Home Manager modules setting default values for `programs.aiAgents.*` options. Each file configures a specific AI agent tool's defaults — model selection, agent definitions, feature flags, themes, hooks, and tool configurations.

Parent: `home-manager/modules/ai-agents/AGENTS.md`

---

## Files

| File                       | Purpose                                                                                     |
| -------------------------- | ------------------------------------------------------------------------------------------- |
| `default.nix`              | Import hub: imports codex, gemini, opencode, pi                                             |
| `codex.nix`                | Codex CLI: model (gpt-5.4), profiles, custom agents, features                               |
| `gemini.nix`               | Gemini CLI: theme (Gruvbox), model aliases, auto-format hooks, security, experimental flags |
| `opencode.nix`             | OpenCode: model (opencode/claude-opus-4-6), 7 agents, 6 commands, LSP, permissions          |
| `pi.nix`                   | Pi CLI: model, thinking level, theme, editor/UI settings                                    |
| `_opencode-agents.nix`     | OpenCode agent definitions (build, plan, review, recon, patch, optimize, android-re)        |
| `_opencode-commands.nix`   | OpenCode slash command definitions (commit-split, refactor, security-audit, etc.)           |
| `_opencode-android-re.nix` | OpenCode Android RE agent definition (imports `../../android-re/_prompt.nix`)               |
| `_opencode-lsp.nix`        | Plain attrset (not a module): LSP server definitions for 9 languages                        |

---

## Conventions

- All files are proper Home Manager modules except `_opencode-lsp.nix` (plain attrset).
- Model references come from `../../helpers/_models.nix` — never hardcode model strings.
- `extraSettings` pattern for complex nested config that doesn't map to typed options.
- Placeholder pattern for secrets: `__OPENROUTER_API_KEY_PLACEHOLDER__` etc., patched during activation.
- Workflow prompts imported from `../../helpers/_workflow-prompts.nix`.

---

## Gotchas

- `gemini.nix` is the largest file (~207 lines) with extensive theme/hook/model alias config.
- `opencode.nix` imports `_opencode-agents.nix`, `_opencode-commands.nix`, and `_opencode-android-re.nix`. The latter imports `../../android-re/_prompt.nix` — creates an indirect dependency on the `android-re/` directory.
- `gemini.nix` references `constants.color.*` for theming — from flake-level constants, not options.
- `codex.nix` sets `trustedProjects` to the System directory path from `config.home.homeDirectory`.
- `_opencode-lsp.nix` is the only non-module file — imported directly by `opencode.nix` as the `lsp` option value.
- Gemini auto-format hooks use inline Bash via string interpolation; formatter branches come from `_formatters.nix`.

---

## Dependencies

- `../../helpers/_models.nix` (all four agent modules)
- `../../helpers/_workflow-prompts.nix` (opencode.nix)
- `../../helpers/_formatters.nix` (gemini.nix)
- `../../android-re/_prompt.nix` (opencode.nix)
- `constants` from flake (gemini.nix for colors)
