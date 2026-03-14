# Noctalia Shell

Custom Wayland desktop shell: bar, launcher, notifications, wallpaper, OSD, control center.
3 modules. **Stylix-exempt** — manages own theming (colors set explicitly in `settings.nix`).

---

## Module Map

| File           | Purpose      | Key Details                                                                                                           |
| -------------- | ------------ | --------------------------------------------------------------------------------------------------------------------- |
| `default.nix`  | Import hub   | Imports `noctalia.homeModules.default` from flake, bar, settings; defines `apiQuotaScript`, `status-notifier-watcher` |
| `bar.nix`      | Bar widgets  | Left (workspaces, window title), center (clock, media), right (system tray, monitoring, power)                        |
| `settings.nix` | Shell config | Theme colors (Gruvbox, hardcoded), dock, wallpaper, OSD, control center, hooks                                        |

---

## Noctalia IPC Protocol

Niri binds communicate with Noctalia via IPC:
`home-manager/modules/niri/binds.nix` uses a `noctalia` helper that calls `noctalia-shell ipc call`, starts Noctalia if needed, and retries once.

**Tight coupling**: Changing Noctalia IPC commands requires updating all `noctalia` calls in `home-manager/modules/niri/binds.nix`.

Used for launcher, clipboard, notifications, session menu, and related shell actions (exact key combos are defined in `home-manager/modules/niri/binds.nix`).

---

## Theming (Stylix-Exempt)

Noctalia ignores Stylix auto-theming. Colors are hardcoded Gruvbox values in `settings.nix`:

- Background: `#282828` / `#32302f`
- Foreground: `#ebdbb2`
- Accent: `#458588` (blue)
- Borders/highlights use Gruvbox palette directly

When Stylix base16 scheme changes, Noctalia colors must be updated **manually** in `settings.nix`.

---

## API Quota Widget

`default.nix` defines `apiQuotaScript` — wraps `scripts/ai/api-quota/api-quota.sh` as a Nix derivation.
Displays Z.AI + Claude Max + Codex usage in the bar's right panel.

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
