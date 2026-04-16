# Noctalia Shell

Custom Wayland desktop shell: bar, launcher, notifications, wallpaper, OSD, control center.
4 modules + custom color scheme + 4 QML plugins. **Stylix-exempt** — manages own theming (colors set explicitly in `settings.nix` and generated from `shared/constants.nix`).

---

## Module Map

| File               | Purpose         | Key Details                                                                                                            |
| ------------------ | --------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `default.nix`      | Import hub      | Imports `noctalia.homeModules.default` from flake, bar, settings, activation; `status-notifier-watcher`                |
| `bar.nix`          | Bar widgets     | Left (clock, system monitor), center (workspace widget), right (media, network, tray, plugins, volume, control center) |
| `settings.nix`     | Shell config    | Theme colors (GruvboxAlt via custom scheme), dock, wallpaper, OSD, control center, hooks                               |
| `activation.nix`   | Activation      | Home Manager activation scripts for Noctalia setup                                                                     |
| `_colorscheme.nix` | Color scheme    | Generates GruvboxAlt JSON from `shared/constants.nix` (dark scheme auto-syncs, light scheme inline)                    |
| `_plugins.nix`     | Plugin registry | Categorizes all 4 QML plugins by activation behavior (`all`, `needsBackup`, `needsMaterialization`)                    |

### `plugins/` (4 QML plugins)

| Plugin                | Purpose                   |
| --------------------- | ------------------------- |
| `browser-launcher/`   | Browser profile launcher  |
| `keybind-cheatsheet/` | Keyboard shortcut overlay |
| `mawaqit/`            | Prayer time widget        |
| `model-usage/`        | AI model usage tracker    |

---

## Noctalia IPC Protocol

Niri binds communicate with Noctalia via IPC:
`home-manager/modules/niri/binds.nix` uses a `noctalia` helper that calls `noctalia-shell ipc call`, starts Noctalia if needed, and retries once.

**Tight coupling**: Changing Noctalia IPC commands requires updating all `noctalia` calls in `home-manager/modules/niri/binds.nix`.

Used for launcher, clipboard, notifications, session menu, and related shell actions (exact key combos are defined in `home-manager/modules/niri/binds.nix`).

---

## Theming (Stylix-Exempt)

Noctalia ignores Stylix auto-theming. Colors derive from `shared/constants.nix` via `_colorscheme.nix`:

- Helper: `_colorscheme.nix` generates the full GruvboxAlt JSON from `constants.color`
- Dark scheme: fully derived from constants (single source of truth)
- Light scheme: uses constants where colors overlap; light-mode-specific values are inline
- Selected via `predefinedScheme = "GruvboxAlt"` in `settings.nix`
- QML plugin files use the same palette via hardcoded color properties

When the scheme changes, update `shared/constants.nix` and (if accent colors shift) the QML plugin colors. No manual JSON editing needed.

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
just home
```

---

## Adding a Bar Widget

1. Edit `bar.nix` — add to the appropriate panel (left, center, or right)
2. If widget needs external data: create script, wrap with `pkgs.writeShellScript`, reference in `default.nix`
3. Run: `just home`
