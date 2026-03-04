# Niri Compositor Configuration

Scrollable tiling Wayland compositor. 7 local modules plus 3 helper scripts (and 2 imported flake modules).
Configures `programs.niri.settings` — all settings live under that namespace.

---

## Module Map

| File | Configures | Key Details |
|------|-----------|-------------|
| `default.nix` | Import hub | Imports `niri.homeModules.config` + `niri.homeModules.stylix` from flake, then 7 local modules |
| `main.nix` | Workspaces, autostart, environment | 5 named workspaces, startup apps, `SSH_AUTH_SOCK` → KeePassXC |
| `binds.nix` | Keybindings | Extensive binds; `noctalia` IPC helper; imports scripts from `scripts/` |
| `input.nix` | Keyboard, mouse, touchpad, trackpoint | Uses `constants.keyboard.*`; Niri adds `terminate:ctrl_alt_bksp` |
| `layout.nix` | Gaps, columns, borders | 3px gaps, 3 preset widths (1/3, 1/2, 2/3), focus-ring disabled (Stylix border instead) |
| `rules.nix` | Window rules | Square corners (`0px`), floating rules, opacity, workspace assignments by `app-id` |
| `idle.nix` | Idle/DPMS | swayidle integration, screen lock timeout |
| `lock.nix` | Screen locker | swaylock fallback configuration |
| `scripts/` | Helper scripts | `color-picker.nix`, `screenshot.nix`, `open-books.nix` — each returns a derivation |

---

## Workspaces

5 named workspaces (ordered by sort key):

| Key | Name | Typical Apps |
|-----|------|-------------|
| `01-browser` | browser | Brave |
| `02-code` | editor | configured editor, terminals |
| `03-social` | social | Telegram, Vesktop |
| `04-media` | media | YouTube Music, FreeTube |
| `05-vpn` | vpn | Mullvad VPN |

Dynamic workspaces 6-9 available via `Mod+6` through `Mod+9`.
Window rules in `rules.nix` assign apps to workspaces by `app-id` regex.

---

## Keybinding Patterns

### Noctalia IPC Helper
`binds.nix` defines a `noctalia` helper that shells out to `noctalia-shell ipc call`, auto-starts Noctalia if IPC is unavailable, then retries the command.
Used for launcher, clipboard, notifications, lock/session controls, and other shell actions.
**Tight coupling**: Changing Noctalia IPC protocol requires updating all `noctalia` calls in `binds.nix`.

### Key Categories
- **App shortcuts**: `Mod+Return` (terminal+zellij), `Mod+Shift+Return` (bare terminal), `Mod+Q` (close)
- **Noctalia**: launcher/clipboard/notifications/session controls (see exact combos in `binds.nix`)
- **Layout**: `Mod+W` (tabbed), `Mod+Comma` (consume into column), `Mod+Slash` (expel)
- **Focus**: `Mod+Arrow`, `Mod+Tab` (next window), `Mod+A` (MRU)
- **Move/Resize**: `Mod+Shift+Arrow` (move), `Mod+Ctrl+Arrow` (resize)
- **Workspaces**: `Mod+1-9`, `Mod+U` (previous), `Mod+Page_Up/Down`
- **Screenshots**: full-screen, window, and annotated capture paths (via `screenshot-annotate`)

### Custom Scripts
Scripts live in `scripts/`, imported in `binds.nix`, and added to `home.packages`:
- **color-picker**: `grim` + `slurp` + `imagemagick` → hex color to clipboard
- **screenshot-annotate**: `grim` + `slurp` + `swappy` → annotated screenshot
- **open-books**: `find` + `wofi` + `zathura` → fuzzy book launcher

Scripts use `pkgsStable` — ensure tool compatibility when updating.

---

## Flake Input Integration

```nix
imports = [
  inputs.niri.homeModules.config   # programs.niri.settings schema
  inputs.niri.homeModules.stylix   # Border colors, cursor from Stylix
];
```

**Critical**: The `niri` flake input does NOT follow nixpkgs (mesa compatibility). See `flake.nix` comment.
The system-level `nixos/modules/niri.nix` applies `inputs.niri.overlays.niri` for `pkgs.niri-stable`.

---

## Conventions

- All settings via `programs.niri.settings.*` — no `home.file` or `xdg.configFile`
- `constants.terminal`, `constants.terminalAppId`, `constants.keyboard.*` used — don't hardcode
- Window rules match by `app-id` regex (Wayland app identifiers, not window titles)
- Layout background is `transparent` (Noctalia wallpaper shows through)
- Focus ring disabled; Stylix controls border colors via `niri.homeModules.stylix`
- Animations use spring physics (`damping-ratio`, `stiffness`, `epsilon`) — not duration-based

---

## Adding a Window Rule

1. Find the app-id: `niri msg windows | grep app-id`
2. Add rule to `rules.nix` in the `window-rules` list
3. Match by `app-id` regex: `matches = [ { app-id = "^com\\.example\\.App$"; } ];`
4. Set properties: `open-floating`, `open-on-workspace`, `default-column-width`, `opacity`, etc.
5. Validate: `just home`

## Adding a Keybinding

1. Add to `programs.niri.settings.binds` in `binds.nix`
2. Format: `"Mod+Key".action.<action> = [ args ];`
3. For Noctalia integration: use `noctalia "command arg"` helper
4. For custom scripts: create in `scripts/`, import in `binds.nix`, add to `home.packages`
5. Validate: `just home`
