# Keybind Cheatsheet Plugin

Keyboard shortcut overlay for the Noctalia shell. Auto-detects the running compositor (Hyprland or Niri), parses config files recursively (following `source`/`include` and globs), and displays categorized keybinds in a multi-column panel.

**Option**: `programs.noctalia.plugins.keybind-cheatsheet` (enabled via parent module)

---

## Structure

| File            | Purpose                                                                                 |
| --------------- | --------------------------------------------------------------------------------------- |
| `manifest.json` | Plugin metadata, entry points, default settings                                         |
| `Main.qml`      | Core: compositor detection, recursive config parsing (Hyprland + Niri), bind extraction |
| `BarWidget.qml` | Bar capsule button with "keyboard" icon                                                 |
| `Panel.qml`     | Popup panel: multi-column keybind display, color-coded badges, auto-height              |
| `Settings.qml`  | Settings: window size, column count (1-4), config file paths, mod key, refresh          |
| `i18n/`         | 21 locale files (see `i18n/AGENTS.md`)                                                  |

---

## Conventions

- Two parsing paths: `parseNextHyprlandFile()` / `parseHyprlandConfig()` and `parseNextNiriFile()` / `parseNiriFileContent()`.
- `CompositorService.isHyprland` / `CompositorService.isNiri` for compositor detection.
- `IpcHandler` with target `plugin:keybind-cheatsheet` exposes `toggle()` for external keybind triggers.
- Column distribution uses a greedy "assign to lightest column" algorithm.
- Dynamic height capped at 90% of screen height.

---

## Gotchas

- `en.json` is the canonical key set — all 20 other locales must match its structure.
- Hyprland workspace category splitting is hardcoded for the Polish category name `"OBSZARY ROBOCZE"`.
- Niri parser handles multiline binds with brace-depth tracking — fragile if KDL syntax changes.
- Glob expansion uses a shell `for` loop capped at 100 files per pattern; line reading capped at 10,000 lines per file.
- Recursive file parsing has a depth limit of 50 with `Component.onDestruction` cleanup.
