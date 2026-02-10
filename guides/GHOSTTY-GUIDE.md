# Ghostty Terminal Guide

Ghostty is a GPU-accelerated terminal emulator with native Wayland support, image protocols (sixel/kitty), and fast performance. It's your primary terminal, typically launched with Zellij for session management.

---

## Launching Ghostty

From Niri:

| Key | What It Does |
|-----|-------------|
| `Super+Return` | Open Ghostty with Zellij |
| `Super+Shift+Return` | Open Ghostty without Zellij |
| `Super+T` | Open scratchpad terminal (floating dropdown) |

From command line:

```bash
ghostty                    # Launch Ghostty
ghostty -e zsh             # Launch with specific shell
ghostty --class=scratchpad # Launch with custom app-id (for window rules)
```

---

## Keybindings

### Copy and Paste

| Key | What It Does |
|-----|-------------|
| `Ctrl+Shift+C` | Copy to clipboard |
| `Ctrl+Shift+V` | Paste from clipboard |

Text is also automatically copied to clipboard when you select it with the mouse (`copy-on-select` is enabled).

### Font Size

| Key | What It Does |
|-----|-------------|
| `Ctrl++` | Increase font size |
| `Ctrl+-` | Decrease font size |
| `Ctrl+0` | Reset font size to default |

### Scrolling

| Key | What It Does |
|-----|-------------|
| `Shift+PageUp` | Scroll up one page |
| `Shift+PageDown` | Scroll down one page |
| `Shift+Home` | Scroll to top of buffer |
| `Shift+End` | Scroll to bottom of buffer |

You can also scroll with the mouse wheel.

### Other

| Key | What It Does |
|-----|-------------|
| `Ctrl+Shift+N` | New window |
| `Ctrl+L` | Clear screen (sends Ctrl+L to shell) |
| `Ctrl+Shift+I` | Toggle inspector (for debugging) |

### URLs

- **Ctrl+Click** on a URL to open it in your browser
- URLs are automatically detected and highlighted

---

## Configuration Highlights

Your Ghostty setup includes:

| Setting | Value | Why |
|---------|-------|-----|
| Font | JetBrainsMono Nerd Font | Ligatures, icons, code readability |
| Font size | System default (from constants) | Consistent with other apps |
| Font thicken | Enabled | Bolder strokes for readability |
| Line height | +10% | Slightly taller lines for readability |
| Theme | Gruvbox Dark | Managed by Stylix for consistency |
| Cursor | Block, blinking, yellow | Gruvbox yellow for visibility |
| Scrollback | 50,000 lines | Large buffer for log viewing |
| Window padding | 8px | Clean spacing |
| Window decorations | Off | Niri handles decorations |
| Copy on select | Enabled | Select text to copy automatically |
| Clipboard paste protection | Enabled | Warns about suspicious pastes |
| Selection highlight | Inverted fg/bg | Clear visibility when selecting text |
| Bold is bright | Disabled | Bold text stays same color (cleaner look) |
| GTK tabs | Hidden | Zellij handles multiplexing |
| VSync | Enabled | Smooth scrolling on Wayland |
| Auto-update | Off | Managed by Nix |

---

## Shell Integration

Ghostty has built-in shell integration for Zsh with these features:

| Feature | What It Does |
|---------|-------------|
| Cursor tracking | Shell knows cursor position for better prompts |
| Sudo detection | Automatic handling of sudo prompts |
| Title updates | Terminal title shows current command/directory |

Shell integration is automatically injected — no manual setup needed.

---

## Mouse Features

| Action | What It Does |
|--------|-------------|
| Select text | Copies to clipboard automatically |
| Ctrl+Click URL | Opens URL in browser |
| Scroll wheel | Scroll through terminal output |
| Mouse hidden while typing | Cleaner visual experience |

---

## Image Support

Ghostty supports image display in the terminal via:

- **Sixel graphics** — Traditional terminal image protocol
- **Kitty image protocol** — Modern image display (used by yazi, ranger)

Apps like `yazi` (file manager) can show image previews directly in Ghostty.

---

## Tips

1. **Use Zellij for sessions.** Ghostty doesn't have built-in tabs/splits — that's what Zellij is for. `Super+Return` opens Ghostty with Zellij automatically.

2. **GTK single instance.** Ghostty uses a single GTK instance for better resource usage. Multiple windows share one process.

3. **No close confirmation.** Ghostty won't ask to confirm close because Zellij handles session persistence. Your work is safe even if you close the terminal.

4. **Clipboard is bidirectional.** Apps can both read and write to your clipboard. This is convenient but be aware of security implications.

5. **Inspector for debugging.** Press `Ctrl+Shift+I` to open the Ghostty inspector — useful for debugging terminal issues or checking escape codes.

---

## Configuration File

| File | What It Controls |
|------|-----------------|
| `home-manager/modules/terminal/ghostty.nix` | All Ghostty settings, keybindings, theme |

To apply changes after editing: `just home` (rebuilds Home Manager configuration).

---

## Quick Reference

| Key | Action |
|-----|--------|
| `Ctrl+Shift+C` | Copy |
| `Ctrl+Shift+V` | Paste |
| `Ctrl++` / `Ctrl+-` | Font size up/down |
| `Ctrl+0` | Reset font size |
| `Shift+PageUp/Down` | Scroll page |
| `Shift+Home/End` | Scroll to top/bottom |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Click` | Open URL |
