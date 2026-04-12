# Noctalia Shell

Custom Wayland desktop shell: bar, launcher, notifications, wallpaper, OSD, control center.
4 modules + custom color scheme. **Stylix-exempt** — manages own theming (colors set explicitly in `settings.nix` and `colorschemes/GruvboxAlt.json`).

---

## Module Map

| File             | Purpose      | Key Details                                                                                                            |
| ---------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `default.nix`    | Import hub   | Imports `noctalia.homeModules.default` from flake, bar, settings, activation; `status-notifier-watcher`                |
| `bar.nix`        | Bar widgets  | Left (clock, system monitor), center (workspace widget), right (media, network, tray, plugins, volume, control center) |
| `settings.nix`   | Shell config | Theme colors (GruvboxAlt via custom scheme), dock, wallpaper, OSD, control center, hooks                               |
| `activation.nix` | Activation   | Home Manager activation scripts for Noctalia setup                                                                     |

---

## Noctalia IPC Protocol

Niri binds communicate with Noctalia via IPC:
`home-manager/modules/niri/binds.nix` uses a `noctalia` helper that calls `noctalia-shell ipc call`, starts Noctalia if needed, and retries once.

**Tight coupling**: Changing Noctalia IPC commands requires updating all `noctalia` calls in `home-manager/modules/niri/binds.nix`.

Used for launcher, clipboard, notifications, session menu, and related shell actions (exact key combos are defined in `home-manager/modules/niri/binds.nix`).

---

## Theming (Stylix-Exempt)

Noctalia ignores Stylix auto-theming. Colors come from a custom GruvboxAlt color scheme:

- Scheme file: `colorschemes/GruvboxAlt.json` (placed at `~/.config/noctalia/colorschemes/GruvboxAlt/GruvboxAlt.json`)
- Selected via `predefinedScheme = "GruvboxAlt"` in `settings.nix`
- Background: `#282828` / `#3c3836`
- Foreground: `#ebdbb2` / `#fbf1c7`
- Outline: `#57514e`
- Hover/Accent: `#83a598`
- QML plugin files use the same palette via hardcoded color properties

When the scheme changes, update `colorschemes/GruvboxAlt.json`, the QML plugin colors, and `shared/constants.nix` (if accent colors shift).

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
