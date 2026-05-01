# Model Usage — Providers

Data-source layer for the model-usage plugin. Each file implements the provider property contract and fetches usage/rate-limit data from its respective backend.

---

## Files

| File             | Data Source                                                                                                 | Strategy              |
| ---------------- | ----------------------------------------------------------------------------------------------------------- | --------------------- |
| `Claude.qml`     | `~/.claude/stats-cache.json`, `~/.claude/history.jsonl`, `~/.claude/.credentials.json`, Anthropic OAuth API | FileView + XHR        |
| `Codex.qml`      | `~/.codex/history.jsonl`, `~/.codex/config.toml`, `~/.codex/auth.json`, session files                       | FileView + Process    |
| `Copilot.qml`    | `gh auth token` + `api.github.com/copilot_internal/user`                                                    | Process + XHR         |
| `OpenRouter.qml` | `OPENROUTER_API_KEY` env, `openrouter.ai/api/v1/key` + activity                                             | Pure XHR (7 parallel) |
| `Zai.qml`        | `/run/secrets/zai_api_key`, `api.z.ai/api/monitor/usage/quota/limit`                                        | Process (`curl`)      |
| `Zen.qml`        | `OPENCODE_ZEN_API_KEY` / `OPENCODE_API_KEY` / `ZEN_API_KEY` env, `opencode.ai`                              | Pure XHR              |

---

## Conventions

- Uniform property interface: all 6 providers expose the same set of properties.
- `rateLimitPercent` as 0.0-1.0 float; `formatResetTime()` converts ISO timestamps to relative time strings.
- Error states: `usageStatusText` for display, `authHelpText` for recovery, `ready` boolean gates rendering.
- Timer-based polling (5-10 min intervals) plus `FileView` reactive updates.

---

## Gotchas

- `formatResetTime()` is a thin wrapper in each provider that delegates to `ProviderUtils.js.formatResetTime()`.
- `resolvePath()` is a thin wrapper in Claude, Codex, and Zai that delegates to `ProviderUtils.js.resolvePath()`.
- Copilot uses internal GitHub API (`copilot_internal/user`) — undocumented, could break.
- Zen sends a real API request (POST with `model: "glm-5-free", input: "hi"`) just to validate the key.
- OpenRouter fires 7 parallel XHR requests for activity data.
- Zai uses `curl` via Process instead of XHR — different error handling pattern.
