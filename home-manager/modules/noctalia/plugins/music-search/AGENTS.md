# Music Search Plugin

Noctalia QML plugin for music search and playback. Searches YouTube/SoundCloud/local files via yt-dlp, plays audio via mpv, maintains a persistent JSON library with tags/ratings/play-counts, and provides a playback queue with auto-advance.

**Option**: `programs.noctalia.plugins.music-search` (enabled via parent module)

---

## Structure

| File                   | Purpose                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
| `manifest.json`        | Plugin metadata, entry points, default settings                                                   |
| `Main.qml`             | Core singleton: state machine, Process executors, JSON file watchers, queue logic (~2060 lines)   |
| `Panel.qml`            | Full panel UI: 3-tab layout (Search/Saved/Queue), playback controls, library browse (~2645 lines) |
| `LauncherProvider.qml` | Launcher search provider with structured library filter parsing (~2900 lines)                     |
| `MusicPreview.qml`     | Preview pane: metadata grid, seek slider, detail cache (LRU, max 50)                              |
| `Settings.qml`         | Settings form: provider, download dir, cache, density, metadata toggles                           |
| `BarWidget.qml`        | Bar pill widget with optional track title on hover                                                |
| `MusicUtils.js`        | Pure JS: `formatDuration()`, `formatRelativeTime()`                                               |
| `musicctl.sh`          | CLI entry point: dispatches to `lib/*.sh` subcommands                                             |
| `i18n/en.json`         | English translations (canonical key set)                                                          |
| `lib/`                 | Backend shell library (see `lib/AGENTS.md`)                                                       |

---

## Architecture

QML + JS + Bash split: QML provides UI and state management; `musicctl.sh` + `lib/*.sh` provide all backend logic via CLI subprocess calls.

- **IPC**: QML watches JSON files in `~/.cache/noctalia/plugins/music-search/` via `FileView`. Shell scripts write; QML reacts.
- **Commands**: Every backend action is a `Process { exec: ["bash", helperPath, "subcommand", ...args] }` call.
- **Guards**: `root.playbackBusy`, `root.queueBusy`, `root.libraryBusy` prevent concurrent conflicting commands.
- **Settings**: `pluginApi.pluginSettings[key] ?? defaults[key] ?? hardcoded_default` cascade.
- **i18n**: All user-visible strings use `pluginApi.tr("key", {"param": value})`.

---

## Gotchas

- All new CLI commands must be added to the `case` block in `musicctl.sh` AND have a corresponding `Process` in `Main.qml`.
- `manifest.json` `defaultSettings` must stay in sync with hardcoded fallback values in QML.
- JSON output from shell scripts is the API contract — changing field names breaks QML parsing.
- `state.json` is ephemeral (auto-recovered); `library.json`, `playlists.json`, `queue.json` are user data.
- External CLI dependencies: `mpv`, `yt-dlp`, `jq`, `ffmpeg`, `ffprobe`, `socat` (or `python3` fallback), `flock`, `shuf`.

---

## Adding a Feature

1. Add shell backend in `lib/*.sh` + dispatch in `musicctl.sh`
2. Add `Process` executor in `Main.qml`
3. Wire UI in `Panel.qml` or `LauncherProvider.qml`
4. Add i18n keys in `i18n/en.json`
5. Add settings (if any) in `Settings.qml` + `manifest.json` defaults
