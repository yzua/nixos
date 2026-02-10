# Niri Window Manager Guide

Welcome! This guide covers everything about your Niri desktop setup. Niri is a **scrollable tiling Wayland compositor** — windows are arranged in columns that scroll horizontally, like an infinite canvas. No grid constraints, no manual splitting. Just columns that flow left and right.

Your setup includes Noctalia Shell (bar, launcher, notifications, wallpaper, OSD) and a full suite of keybindings ported from Hyprland.

---

## What Makes Niri Different

Traditional tiling WMs (i3, Hyprland, Sway) divide your screen into a grid. Niri doesn't. Instead:

- **Windows are columns** on an infinite horizontal strip
- **Scroll left/right** to navigate between columns
- **Each column can hold multiple windows** stacked vertically
- **Workspaces scroll vertically** — each workspace is its own horizontal strip
- **No layout modes to learn** — there's just columns

Think of it like a web page that scrolls sideways. The focused column centers itself on screen automatically.

---

## Your Workspaces

Five named workspaces are preconfigured, each with auto-launching apps:

| # | Workspace | Apps (auto-start) | Access |
|---|-----------|-------------------|--------|
| 1 | 󰖟 browser | Brave (full-width) | `Super+1` |
| 2 | 󰨞 code | VSCode, Ghostty | `Super+2` |
| 3 | 󰍡 social | Vesktop (Discord), Telegram | `Super+3` |
| 4 | 󰎆 media | Spotube (full-width), FreeTube | `Super+4` |
| 5 | 󰦝 vpn | Mullvad VPN (floating) | `Super+5` |

Workspaces 6–9 are available as unnamed extras (`Super+6` through `Super+9`).

Apps are assigned to workspaces via window rules — when Brave opens, it goes to browser workspace automatically. You never have to manually place them.

---

## The 10 Keybindings You Need to Survive

Learn these first. Everything else can wait.

| # | Key | What It Does | When to Use |
|---|-----|-------------|-------------|
| 1 | `Super+Return` | Open terminal (Ghostty) | Need a terminal |
| 2 | `Super+D` | Open app launcher (Noctalia) | Launch any app |
| 3 | `Super+Q` | Close focused window | Done with a window |
| 4 | `Super+Left/Right` | Focus column left/right | Navigate between windows |
| 5 | `Super+1–5` | Switch to workspace | Jump to a workspace |
| 6 | `Super+F` | Toggle floating | Pull a window out of tiling |
| 7 | `Super+M` | Maximize column | Make column fill the screen |
| 8 | `Super+V` | Clipboard history | Paste from history |
| 9 | `Print` | Screenshot (region select) | Capture a region |
| 10 | `Super+Shift+Escape` | Session menu (logout/shutdown) | Power off or log out |

---

## Application Launchers

| Key | What It Does |
|-----|-------------|
| `Super+Return` | Terminal (Ghostty with Zellij) |
| `Super+Shift+Return` | Terminal (Ghostty without Zellij) |
| `Super+T` | Scratchpad terminal (floating, drops down from top) |
| `Super+D` | App launcher (Noctalia) |
| `Super+B` | Web browser (personal profile) |
| `Super+Shift+R` | File manager (Nautilus) |
| `Super+E` | Emoji picker (bemoji) |
| `Super+Period` | Emoji picker (Noctalia launcher) |

---

## Window Management

### Focus Navigation

| Key | What It Does |
|-----|-------------|
| `Super+Left` | Focus column to the left |
| `Super+Right` | Focus column to the right |
| `Super+Up` | Focus window above (in same column) |
| `Super+Down` | Focus window below (in same column) |
| `Super+Tab` | Focus next column (same as Right) |
| `Super+Shift+Tab` | Focus previous column (same as Left) |
| `Super+A` | Focus next window/workspace down (MRU order) |
| `Super+Shift+A` | Focus previous window/workspace up (MRU order) |
| `Super+Shift+Home` | Focus first column |
| `Super+Shift+End` | Focus last column |

### Moving Windows

| Key | What It Does |
|-----|-------------|
| `Super+Shift+Left` | Move column left |
| `Super+Shift+Right` | Move column right |
| `Super+Shift+Up` | Move window up (within column) |
| `Super+Shift+Down` | Move window down (within column) |
| `Super+Ctrl+Home` | Move column to first position |
| `Super+Ctrl+End` | Move column to last position |

### Resizing Windows

| Key | What It Does |
|-----|-------------|
| `Super+Ctrl+Left` | Shrink column width by 10% |
| `Super+Ctrl+Right` | Grow column width by 10% |
| `Super+Ctrl+Up` | Shrink window height by 10% |
| `Super+Ctrl+Down` | Grow window height by 10% |
| `Super+Ctrl+R` | Reset window height to default |
| `Super+R` | Cycle preset column widths (1/3 → 1/2 → 2/3) |
| `Super+Shift+F5` | Cycle preset window heights |

### Window States

| Key | What It Does |
|-----|-------------|
| `Super+Q` | Close window |
| `Super+F` | Toggle floating (pull out of / push into tiling) |
| `Super+M` | Maximize column (fill screen width) |
| `Super+Shift+M` | Fullscreen window (true fullscreen) |
| `Super+C` | Center the focused column on screen |
| `Super+Shift+O` | Toggle window opacity (transparency on/off) |

### Column Management

Niri's unique feature: columns can hold multiple windows stacked vertically, and you can merge/split them.

| Key | What It Does |
|-----|-------------|
| `Super+Comma` | Consume window from the left into this column (or expel left) |
| `Super+Slash` | Consume window from the right into this column (or expel right) |
| `Super+W` | Toggle tabbed display for the column |

**How consume/expel works**: If the adjacent column has a window, it gets absorbed into your column as a stacked window. If your column has multiple windows, the edge window gets expelled into its own column.

---

## Workspace Navigation

| Key | What It Does |
|-----|-------------|
| `Super+1` | Go to 󰖟 browser workspace |
| `Super+2` | Go to 󰨞 code workspace |
| `Super+3` | Go to 󰍡 social workspace |
| `Super+4` | Go to 󰎆 media workspace |
| `Super+5–9` | Go to workspace 5–9 |
| `Super+Page_Up` | Go to workspace above |
| `Super+Page_Down` | Go to workspace below |
| `Super+U` | Go to previous workspace (back-and-forth) |
| `Super+Grave` | Toggle overview mode (all workspaces/windows) |

### Moving Windows Between Workspaces

| Key | What It Does |
|-----|-------------|
| `Super+Shift+1` | Move column to 󰖟 browser workspace |
| `Super+Shift+2` | Move column to 󰨞 code workspace |
| `Super+Shift+3` | Move column to 󰍡 social workspace |
| `Super+Shift+4` | Move column to 󰎆 media workspace |
| `Super+Shift+5–9` | Move column to workspace 5–9 |
| `Super+Shift+Page_Up` | Move column to workspace above |
| `Super+Shift+Page_Down` | Move column to workspace below |

### Reordering Workspaces

| Key | What It Does |
|-----|-------------|
| `Super+Ctrl+Page_Up` | Move entire workspace up |
| `Super+Ctrl+Page_Down` | Move entire workspace down |

---

## Multi-Monitor

### Focus Between Monitors

| Key | What It Does |
|-----|-------------|
| `Super+Alt+Left` | Focus monitor to the left |
| `Super+Alt+Right` | Focus monitor to the right |
| `Super+Alt+Up` | Focus monitor above |
| `Super+Alt+Down` | Focus monitor below |

### Move Columns Between Monitors

| Key | What It Does |
|-----|-------------|
| `Super+Alt+Shift+Left` | Move column to left monitor |
| `Super+Alt+Shift+Right` | Move column to right monitor |
| `Super+Alt+Shift+Up` | Move column to upper monitor |
| `Super+Alt+Shift+Down` | Move column to lower monitor |

### Move Workspaces Between Monitors

| Key | What It Does |
|-----|-------------|
| `Super+Alt+Shift+Page_Up` | Move workspace to upper monitor |
| `Super+Alt+Shift+Page_Down` | Move workspace to lower monitor |

---

## Screenshots and Utilities

Screenshots are saved to `~/Screens/screenshot-YYYY-MM-DD-HH-MM-SS.png` and also copied to clipboard.

| Key | What It Does |
|-----|-------------|
| `Print` | Interactive region select (draw a box) |
| `Super+Print` | Capture entire screen + notification |
| `Super+Shift+Print` | Capture focused window + notification |
| `Super+Alt+Print` | Annotated screenshot (region → swappy editor for arrows, text, blur) |
| `Super+Shift+I` | Color picker (pick a pixel → hex color copied to clipboard) |

---

## Volume, Brightness, and Media

### Volume Control

| Key | What It Does |
|-----|-------------|
| `Super+=` | Volume up 5% |
| `Super+-` | Volume down 5% |
| `XF86AudioRaiseVolume` | Volume up 5% (works when locked) |
| `XF86AudioLowerVolume` | Volume down 5% (works when locked) |
| `XF86AudioMute` | Toggle mute (works when locked) |
| `XF86AudioMicMute` | Toggle mic mute (works when locked) |

### Volume via Noctalia OSD

These trigger Noctalia's on-screen volume indicator:

| Key | What It Does |
|-----|-------------|
| `Super+Shift+=` | Volume up (with OSD) |
| `Super+Shift+-` | Volume down (with OSD) |
| `Super+Shift+BackSpace` | Toggle mute (with OSD) |

### Brightness

| Key | What It Does |
|-----|-------------|
| `Super+]` | Brightness up 10% |
| `Super+[` | Brightness down 10% |
| `Super+Shift+]` | Brightness up (with Noctalia OSD) |
| `Super+Shift+[` | Brightness down (with Noctalia OSD) |

### Media Playback

All media keys work when the screen is locked.

| Key | What It Does |
|-----|-------------|
| `XF86AudioPlay` | Play/pause |
| `XF86AudioPause` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

---

## Noctalia Shell Integration

Noctalia Shell provides the bar, launcher, notifications, lock screen, wallpaper, and OSD. All accessible via keybindings:

| Key | What It Does |
|-----|-------------|
| `Super+D` | Toggle app launcher |
| `Super+V` | Clipboard history (via cliphist) |
| `Super+Period` | Emoji picker (in launcher) |
| `Super+N` | Toggle notification history |
| `Super+Shift+C` | Toggle control center |
| `Super+Shift+D` | Toggle dark mode |
| `Super+Shift+Escape` | Session menu (logout, shutdown, reboot) |

---

## Lock Screen and Idle

### Manual Lock

| Key | What It Does |
|-----|-------------|
| `Super+Home` | Lock screen (Noctalia) |
| `Super+Ctrl+L` | Lock screen (Noctalia) — alternative |

### Automatic Idle Chain

Your system follows this idle sequence:

| Timeout | Action | What Happens |
|---------|--------|-------------|
| 3 minutes | Dim | Screen brightness drops to 30% (restores on activity) |
| 8 minutes | Lock | Noctalia lock screen activates |
| 20 minutes | DPMS off | Monitors power off (wake on any input) |

The lock screen also activates automatically before sleep and when you run `loginctl lock-session`. Clipboard history is wiped on lock for security.

---

## Power Management

| Key | What It Does |
|-----|-------------|
| `Super+Shift+P` | Turn off monitors immediately |
| `Super+Shift+Escape` | Session menu (logout/sleep/shutdown options) |

---

## Window Rules

These rules run automatically. You don't trigger them — they apply when matching windows appear.

### Floating Windows (auto-float)

These apps open floating instead of tiled:

| App | Why |
|-----|-----|
| Celluloid (video player) | Media player — needs its own size |
| Amberol (music player) | Small music player |
| imv (image viewer) | Image viewer |
| Show Me The Key | Keystroke display overlay |
| Telegram Media Viewer | Photo/video overlay |
| Nautilus Previewer (Sushi) | Quick-look file preview |
| pwvucontrol, nm-connection-editor, blueman-manager | System setting dialogs |
| GNOME Calculator, qalculate-gtk | Calculator apps |
| KeePassXC | Password manager |
| xdg-desktop-portal-gtk, xdg-desktop-portal-gnome | File picker / dialog windows |
| Picture-in-Picture | Browser PiP windows |
| Scratchpad terminal | Dropdown terminal (app-id: `scratchpad`) |
| Mullvad VPN | VPN control window |

### Workspace Assignments (auto-placement)

| App | Workspace | Width |
|-----|-----------|-------|
| Brave | 󰖟 browser | Full width |
| VSCode | 󰨞 code | Default (50%) |
| Ghostty | 󰨞 code | Default (50%) |
| Vesktop (Discord) | 󰍡 social | Default (50%) |
| Telegram | 󰍡 social | Default (50%) |
| Spotube | 󰎆 media | Full width |
| FreeTube | 󰎆 media | Default (50%) |
| Mullvad VPN | 󰦝 vpn | Floating |

### Visual Rules

| Rule | Target | Effect |
|------|--------|--------|
| Corner radius (10px) | All windows | Rounded corners, clipped to geometry |
| Transparency (92%) | Ghostty, kitty, foot | Slight see-through for terminals |
| Inactive dim (95%) | All inactive windows | Subtle dimming to highlight focus |
| Shadows | Floating windows | Drop shadow on floating windows |
| Scroll factor (0.75) | Brave, Firefox, Chromium | Slower scroll speed in browsers |

### Special Rules

| Rule | Target | Effect |
|------|--------|--------|
| Block screen capture | 1Password | Hidden during screencasts/recordings |
| Hidden + block capture | xwaylandvideobridge | Invisible helper for screen sharing |
| PiP positioning | Picture-in-Picture | 480x270, bottom-right with 32px offset |
| Scratchpad positioning | scratchpad terminal | 60% width, 40% height, drops from top-center |

---

## Input Configuration

### Keyboard

- **Layouts**: US English + Arabic (QWERTY variant)
- **Layout toggle**: `Caps Lock` switches between US and Arabic
- **Caps Lock LED**: Indicates active layout
- **Emergency exit**: `Ctrl+Alt+Backspace` terminates the session
- **Key repeat**: 25 chars/sec after 600ms delay

### Touchpad

- **Tap to click**: Enabled
- **Natural scroll**: Enabled (two-finger scroll direction matches content)
- **Disable while typing**: Enabled

### Mouse

- **Acceleration**: Flat (no acceleration, 1:1 movement)
- **Focus follows mouse**: Enabled (hover to focus, no scroll stealing)
- **Warp to focus**: Mouse teleports to newly focused window

---

## Layout Details

- **Gaps**: 8px between all windows
- **Default column width**: 50% of screen
- **Preset widths**: Cycle through 1/3, 1/2, 2/3 with `Super+R`
- **Borders**: 2px wide, colors set by Stylix (Gruvbox theme)
- **Focus ring**: Disabled (border-only)
- **Center on overflow**: Focused column auto-centers when it would be off-screen
- **Background**: Transparent (Noctalia wallpaper shows through)
- **CSD**: Disabled (server-side decorations preferred)

---

## Auto-Start Services

These launch automatically when Niri starts:

| Service | Purpose |
|---------|---------|
| xwayland-satellite | X11 app compatibility (Java Swing, etc.) |
| noctalia-shell | Bar, launcher, notifications, wallpaper, OSD |
| mullvad-vpn | VPN client |
| wl-paste (text) + cliphist | Clipboard history for text |
| wl-paste (image) + cliphist | Clipboard history for images |
| wl-clip-persist | Keep clipboard after app closes |
| swayidle | Idle management (dim → lock → DPMS) |

---

## Common "I'm Stuck" Solutions

### "I can't find my window!"

It's probably in another column off-screen. Press `Super+Left/Right` to scroll through columns, or `Super+Grave` to open the overview and see everything.

### "My window is floating and I want it tiled"

Press `Super+F` to toggle floating off. The window will snap back into the column layout.

### "A window opened on the wrong workspace"

Press `Super+Shift+1–9` to move it to the correct workspace. Window rules handle most apps automatically, but new/unknown apps land on the current workspace.

### "I want a window to fill the whole screen"

- `Super+M` — maximize column (fills width, still has gaps and bar)
- `Super+Shift+M` — true fullscreen (no bar, no gaps, no borders)

### "My column has too many windows stacked"

Press `Super+Slash` or `Super+Comma` to expel a window from the column into its own column.

### "I accidentally closed something"

Niri doesn't have an undo for closed windows. Relaunch the app with `Super+D`.

### "How do I see all my workspaces at once?"

Press `Super+Grave` (the backtick key) to toggle the overview. It shows all workspaces and windows.

### "The screen locked and I can't get back in"

Move the mouse or press any key to wake the screen (if DPMS turned it off). Then enter your password on the Noctalia lock screen.

### "I want to switch keyboard layout"

Press `Caps Lock` to toggle between US English and Arabic.

### "How do I take a screenshot of a specific window?"

Press `Super+Shift+Print`. It captures the focused window and saves to `~/Screens/`.

---

## Tips and Power-User Tricks

1. **Use the overview liberally.** `Super+Grave` gives you a bird's-eye view of everything. Great for finding lost windows or getting oriented.

2. **Tab-cycle is fast.** `Super+Tab` / `Super+Shift+Tab` to cycle columns is faster than arrow keys for quick switches.

3. **Scratchpad terminal is your best friend.** `Super+T` drops a floating terminal from the top. Great for quick commands without leaving your workflow. Press `Super+T` again to dismiss (or `Super+Q` to close).

4. **Column width presets save time.** `Super+R` cycles between 1/3, 1/2, and 2/3 width. Way faster than dragging or using `Super+Ctrl+Left/Right` for fine adjustments.

5. **Consume/expel for flexible layouts.** `Super+Comma` and `Super+Slash` let you merge windows into stacked columns or split them apart. This is Niri's answer to manual tiling.

6. **Back-and-forth workspace.** `Super+U` toggles between your current and previous workspace. Essential for quick context switches between code and browser.

7. **PiP workflow.** Open a video in Picture-in-Picture mode in your browser — it auto-floats to the bottom-right at 480x270. Works on every workspace.

8. **Clipboard history is powerful.** `Super+V` opens the Noctalia launcher in clipboard mode. Every text and image you've copied is searchable. Clipboard is wiped on lock for security.

9. **Two emoji pickers.** `Super+E` opens bemoji (terminal-based, fast). `Super+Period` opens the Noctalia launcher emoji picker (visual, searchable).

10. **Monitor management.** For multi-monitor setups, `Super+Alt+Arrow` navigates monitors, `Super+Alt+Shift+Arrow` moves columns between monitors. Entire workspaces can move between monitors with `Super+Alt+Shift+Page_Up/Down`.

---

## Quick Reference — All Keybindings

### Applications

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal (Ghostty) |
| `Super+Shift+Return` | Terminal (no Zellij) |
| `Super+T` | Scratchpad terminal (floating) |
| `Super+D` | App launcher |
| `Super+B` | Web browser |
| `Super+Shift+R` | File manager (Nautilus) |
| `Super+E` | Emoji picker (bemoji) |
| `Super+Period` | Emoji picker (Noctalia) |

### Windows

| Key | Action |
|-----|--------|
| `Super+Q` | Close window |
| `Super+F` | Toggle floating |
| `Super+M` | Maximize column |
| `Super+Shift+M` | Fullscreen |
| `Super+C` | Center column |
| `Super+Shift+O` | Toggle opacity |
| `Super+R` | Cycle column width preset (1/3 → 1/2 → 2/3) |
| `Super+Shift+F5` | Cycle window height preset |
| `Super+W` | Toggle tabbed column |

### Focus

| Key | Action |
|-----|--------|
| `Super+Left/Right` | Focus column left/right |
| `Super+Up/Down` | Focus window up/down (in column) |
| `Super+Tab` | Focus next column |
| `Super+Shift+Tab` | Focus previous column |
| `Super+A` | Focus next window/workspace (MRU) |
| `Super+Shift+A` | Focus previous window/workspace (MRU) |
| `Super+Shift+Home/End` | Focus first/last column |

### Move

| Key | Action |
|-----|--------|
| `Super+Shift+Left/Right` | Move column left/right |
| `Super+Shift+Up/Down` | Move window up/down (in column) |
| `Super+Ctrl+Home/End` | Move column to first/last |
| `Super+Comma` | Consume/expel window left |
| `Super+Slash` | Consume/expel window right |

### Resize

| Key | Action |
|-----|--------|
| `Super+Ctrl+Left/Right` | Column width ±10% |
| `Super+Ctrl+Up/Down` | Window height ±10% |
| `Super+Ctrl+R` | Reset window height |

### Workspaces

| Key | Action |
|-----|--------|
| `Super+1–9` | Focus workspace 1–9 |
| `Super+Shift+1–9` | Move column to workspace 1–9 |
| `Super+Page_Up/Down` | Focus workspace above/below |
| `Super+Shift+Page_Up/Down` | Move column to workspace above/below |
| `Super+Ctrl+Page_Up/Down` | Move workspace up/down |
| `Super+U` | Previous workspace (back-and-forth) |
| `Super+Grave` | Toggle overview |

### Multi-Monitor

| Key | Action |
|-----|--------|
| `Super+Alt+Arrow` | Focus monitor in direction |
| `Super+Alt+Shift+Arrow` | Move column to monitor in direction |
| `Super+Alt+Shift+Page_Up/Down` | Move workspace to monitor above/below |

### Screenshots and Utilities

| Key | Action |
|-----|--------|
| `Print` | Region select |
| `Super+Print` | Entire screen |
| `Super+Shift+Print` | Focused window |
| `Super+Alt+Print` | Annotated screenshot (swappy) |
| `Super+Shift+I` | Color picker (hex → clipboard) |

### Media

| Key | Action |
|-----|--------|
| `Super+=` / `Super+-` | Volume up/down 5% |
| `Super+Shift+=` / `Super+Shift+-` | Volume up/down (with OSD) |
| `Super+Shift+BackSpace` | Toggle mute (with OSD) |
| `Super+]` / `Super+[` | Brightness up/down 10% |
| `Super+Shift+]` / `Super+Shift+[` | Brightness up/down (with OSD) |
| `XF86Audio*` | Hardware media keys (work when locked) |

### System

| Key | Action |
|-----|--------|
| `Super+Home` | Lock screen |
| `Super+Ctrl+L` | Lock screen (alternative) |
| `Super+Shift+P` | Power off monitors |
| `Super+Shift+Escape` | Session menu |
| `Super+N` | Notification history |
| `Super+Shift+C` | Control center |
| `Super+Shift+D` | Toggle dark mode |
| `Super+V` | Clipboard history |
| `Super+Shift+H` | Show hotkey overlay |

### Niri Column Model Legend

```
Workspace (horizontal scroll →)
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Column 1│ │ Column 2│ │ Column 3│
│         │ │┌───────┐│ │         │
│  Brave  │ ││ VSCode││ │  Term   │
│         │ │├───────┤│ │         │
│         │ ││ Term  ││ │         │
│         │ │└───────┘│ │         │
└─────────┘ └─────────┘ └─────────┘
← scroll ───── visible ──── scroll →
```

Column 2 holds two windows stacked vertically (merged with `Super+Comma`/`Super+Slash`). The visible area scrolls to keep the focused column centered.

---

## Configuration Files

| File | What It Controls |
|------|-----------------|
| `home-manager/modules/niri/main.nix` | Layout, window rules, workspaces, animations, input, auto-start |
| `home-manager/modules/niri/binds.nix` | All keybindings and custom scripts |
| `home-manager/modules/niri/idle.nix` | Idle timeouts (dim → lock → DPMS) |
| `home-manager/modules/niri/lock.nix` | Swaylock fallback configuration |
| `home-manager/modules/niri/default.nix` | Module imports and Niri flake integration |

To apply changes after editing: `just home` (rebuilds Home Manager configuration).
