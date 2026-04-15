# Model Usage Plugin

QML plugin for the Noctalia shell that tracks AI coding assistant usage (Claude Code, Codex, GitHub Copilot, OpenRouter, Zen, Z.AI) and displays stats in the bar widget and detail panel.

**Option**: `programs.noctalia.plugins.model-usage` (enabled via parent module)

---

## Structure

| File            | Purpose                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| `manifest.json` | Plugin metadata, entry points, default settings for all 6 providers                                    |
| `Main.qml`      | Plugin controller: loads providers via `Loader`, manages active/cycle mode, format helpers             |
| `BarWidget.qml` | Bar capsule: provider icon + metric, right-click context menu, tooltip                                 |
| `Panel.qml`     | Detail panel: tabbed per-provider view with rate limit bars, today stats, 7-day chart, model breakdown |
| `Settings.qml`  | Settings: bar mode, cycle interval, metric, refresh interval, per-provider toggles, API key inputs     |
| `providers/`    | 6 provider data-source implementations (see `providers/AGENTS.md`)                                     |

---

## Provider Contract

Each provider in `providers/` exposes a fixed property interface: `providerId`, `providerName`, `rateLimitPercent`, `todayPrompts`, `todayTotalTokens`, `modelUsage`, `usageStatusText`, `refresh()`, `formatResetTime()`, etc.

---

## Conventions

- Providers are lazily loaded via `Loader { active: root.providerEnabled("id") }`.
- Data sources: local file watchers (Claude/Codex), Process commands (`gh`, `cat`, `curl`), XHR REST API calls (Copilot/OpenRouter/Zen).
- Settings cascade: `pluginApi.pluginSettings[key] ?? defaults[key] ?? fallback`.
- Styling uses `Style.*` and `Color.*` tokens from the Noctalia theme system.

---

## Gotchas

- Adding a new provider requires: QML file with full property interface, `Loader` in `Main.qml`, entry in `providers` and `enabledProviders` arrays (both must match), toggle in `Settings.qml`, defaults in `manifest.json`.
- `formatResetTime()` is duplicated across all 6 providers — any fix must be replicated 6 times.
- `providers` array in `Main.qml` uses a hardcoded filter order (codex, zai, claude, copilot, openrouter, zen).
- No Nix files in this directory — the plugin is purely QML.
