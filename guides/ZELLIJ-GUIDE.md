# Zellij Guide

Zellij is a terminal multiplexer — it lets you split your terminal into panes, organize them into tabs, and persist sessions across disconnects. Think of it as tmux, but with a plugin system, better defaults, and a discoverable UI. Your setup has custom Vim-style keybindings, a Gruvbox status bar, and several community plugins.

---

## Starting Zellij

```bash
zellij                          # Start or attach to default session
zellij -s myproject             # Start a named session
zellij attach myproject         # Attach to an existing session
zellij -l dev                   # Start with the "dev" layout
zellij -l monitoring            # Start with the "monitoring" layout
zellij list-sessions            # List all sessions
zellij kill-session myproject   # Kill a named session
zellij kill-all-sessions        # Kill all sessions
```

Zellij **auto-starts** with every interactive shell. Your Zsh `initContent` runs `zellij attach --create main` — this attaches to the `main` session (or creates it if it doesn't exist). SSH sessions are excluded. The Home Manager `enableZshIntegration` option is disabled because its built-in `zellij attach -c` breaks with multiple sessions; the custom initContent replaces it with a smarter approach.

To start a **separate named session** instead of the default `main`, run manually:

---

## Modes

Zellij is modal, like Vim. The current mode is shown in the bottom-left of the status bar (colored label). Most of your time is spent in **Normal** mode.

| Mode | Color | How to Enter | What It Does |
|------|-------|-------------|--------------|
| **Normal** | Gray | `Esc` from any mode | Default. All Alt shortcuts work here |
| **Locked** | Yellow | `Ctrl g` | Passes all keys to the running program |
| **Scroll** | Green | `Ctrl s` | Navigate scrollback with Vim keys |
| **Search** | Purple | `/` or `s` from Scroll mode | Search through scrollback |
| **Session** | Red | `Ctrl o` | Session management (detach) |
| **Resize** | Orange | (default bindings) | Resize panes |
| **Pane** | Green | (default bindings) | Pane management |
| **Tab** | Blue | (default bindings) | Tab management |
| **Move** | Gold | (default bindings) | Move panes around |

**Auto-lock**: The `zellij-autolock` plugin automatically switches to Locked mode when you're inside `nvim`, `vim`, `git`, `fzf`, `zoxide`, `atuin`, or `lazygit`. It switches back when you exit.

---

## Panes

Panes split your terminal screen. You can have as many as you want in any tab.

| Key | Action |
|-----|--------|
| `Alt n` | New pane (auto-placed) |
| `Alt s` | Split horizontally (new pane below) |
| `Alt v` | Split vertically (new pane right) |
| `Alt x` | Close focused pane |
| `Alt z` | Toggle fullscreen (zoom) for focused pane |
| `Alt w` | Toggle floating panes |
| `Alt f` | Toggle pane between floating and embedded |

### Navigating Between Panes

| Key | Action |
|-----|--------|
| `Alt h` | Focus left (or previous tab at screen edge) |
| `Alt j` | Focus down |
| `Alt k` | Focus up |
| `Alt l` | Focus right (or next tab at screen edge) |

### Resizing Panes

| Key | Action |
|-----|--------|
| `Alt =` | Increase pane size |
| `Alt -` | Decrease pane size |

---

## Tabs

Tabs group sets of panes. Each tab is a separate workspace.

| Key | Action |
|-----|--------|
| `Alt Enter` | New tab |
| `Alt q` | Close current tab |
| `Alt 1`-`Alt 9` | Jump to tab by number |
| `Alt 0` | Toggle between last two tabs |
| `Alt .` | Move tab right |
| `Alt ,` | Move tab left |

---

## Sessions

Sessions persist your entire workspace. If your terminal crashes or you close the window, everything survives.

| Key | Action |
|-----|--------|
| `Ctrl o` | Enter Session mode |
| `d` (in Session mode) | Detach from session |
| `Esc` (in Session mode) | Back to Normal |
| `Alt o` | Open session manager (floating plugin) |

Sessions auto-serialize to disk (`session_serialization = true`), so they survive reboots. Use `zellij attach` to reconnect.

---

## Scrollback and Copy Mode

Enter scroll mode to navigate through terminal output. This is where you browse history, select text, and search.

### Entering Scroll Mode

| Key | Action |
|-----|--------|
| `Ctrl s` | Enter Scroll mode (from any mode except Locked) |

### Navigating Scrollback (in Scroll Mode)

| Key | Action |
|-----|--------|
| `j` / `Down` | Scroll down one line |
| `k` / `Up` | Scroll up one line |
| `d` / `Ctrl d` | Half page down |
| `u` / `Ctrl u` | Half page up |
| `Ctrl f` / `PageDown` | Full page down |
| `Ctrl b` / `PageUp` | Full page up |
| `g` | Scroll to top |
| `G` | Scroll to bottom |
| `e` | Edit scrollback in Neovim |
| `Esc` / `q` | Exit scroll mode |

### Copying Text

Text selection uses the mouse. With `copy_on_select = true` and `copy_command = "wl-copy"`:

1. **Click and drag** to select text — it copies to clipboard automatically on release
2. **Right-click** to paste (in most terminals)
3. For keyboard-based copying, press `e` in Scroll mode to open the full scrollback in Neovim, then use Vim selection (`v`, `V`, `Ctrl+v`) to select and `y` to yank

The scrollback buffer holds **50,000 lines** per pane.

### Searching Scrollback

From Scroll mode, press `/` or `s` to enter search:

| Key | Action |
|-----|--------|
| `/` or `s` (in Scroll) | Start search (type your query, press Enter) |
| `Esc` (while typing) | Cancel search, back to Scroll |
| `n` (in Search) | Next match (downward) |
| `N` (in Search) | Previous match (upward) |
| `c` (in Search) | Toggle case sensitivity |
| `w` (in Search) | Toggle wrap around |
| `o` (in Search) | Toggle whole word matching |
| `j`/`k` (in Search) | Scroll while viewing results |
| `Esc` / `q` (in Search) | Exit search |

---

## Layouts

Layouts define the initial pane arrangement when starting Zellij. Three layouts are configured:

### Default Layout

```bash
zellij                    # Uses default layout
```

Single tab, single pane, with the zjstatus Gruvbox bar at the bottom.

### Dev Layout

```bash
zellij -l dev
```

Two tabs pre-configured for development:

- **code** (focused): 75% Neovim | 25% split between a shell and lazygit
- **servers**: Empty pane for running dev servers

### Monitoring Layout

```bash
zellij -l monitoring
```

Two tabs for system monitoring:

- **system** (focused): btop and nvtop side by side
- **logs**: Live `journalctl -f` output

---

## Layout Cycling

Within any tab, you can cycle through different pane arrangements:

| Key | Action |
|-----|--------|
| `Alt [` | Previous layout variant |
| `Alt ]` | Next layout variant |

---

## Installed Plugins

### zjstatus (Status Bar)

Gruvbox-themed status bar showing the current mode, open tabs, and time. Always visible at the bottom of every tab. No interaction needed — it updates automatically.

### zellij-autolock (Auto Lock)

Automatically switches to Locked mode when a trigger program is detected (nvim, vim, git, fzf, zoxide, atuin, lazygit). Switches back 0.3s after the program exits. This means your Alt keybindings won't interfere with Neovim.

### monocle (Fuzzy Finder)

| Key | Action |
|-----|--------|
| `Alt p` | Open monocle (floating) |

Fuzzy-find and open files directly from Zellij. Like a built-in fzf for file navigation.

### room (Session/Pane Switcher)

| Key | Action |
|-----|--------|
| `Alt r` | Open room (floating) |

Fuzzy-find and switch between panes and tabs. Case-insensitive search.

### harpoon (Pane Bookmarks)

| Key | Action |
|-----|--------|
| `Alt b` | Open harpoon (floating) |

Bookmark panes and quickly jump between them. Like Neovim's harpoon plugin but for Zellij panes.

### zellij-forgot (Keybinding Helper)

| Key | Action |
|-----|--------|
| `Alt /` | Open zellij-forgot (floating) |

Forgot a keybinding? This plugin shows all configured Zellij keybindings in a searchable floating panel. It auto-loads your actual bindings.

### multitask (Multi-Pane Command Runner)

| Key | Action |
|-----|--------|
| `Alt m` | Open multitask (embedded) |

Run the same command across multiple panes simultaneously.

---

## Miscellaneous

| Key | Action |
|-----|--------|
| `Alt e` | Open scrollback in Neovim (from any mode) |
| `Ctrl g` | Toggle Locked mode |

### Settings Summary

| Setting | Value |
|---------|-------|
| Default shell | zsh |
| Pane frames | Off (borderless) |
| Mouse | Enabled |
| Copy | `wl-copy` (Wayland), copy on select |
| Scrollback | 50,000 lines |
| Session persistence | Enabled (survives crashes) |
| Force close behavior | Detach (not quit) |
| Auto-layout | Enabled |
| Scrollback editor | Neovim |

---

## Common Scenarios

### "I want to scroll up and see previous output"

Press `Ctrl s` to enter Scroll mode, then `k` to scroll up or `Ctrl u` for half-page jumps. Press `Esc` to exit.

### "I want to search for something in terminal output"

Press `Ctrl s` then `/`, type your search query, press `Enter`. Use `n`/`N` to jump between matches.

### "I want to copy text from the terminal"

Click and drag with the mouse. Text is automatically copied to clipboard on release. Paste with `Ctrl+Shift+V` or middle-click.

### "I want to run a dev server alongside my editor"

Use `zellij -l dev` to get a pre-built layout with Neovim, a shell, and lazygit. Or press `Alt s` / `Alt v` to split the current pane.

### "My keybindings aren't working inside Neovim"

The autolock plugin puts Zellij into Locked mode when Neovim is focused. This is intentional — it ensures your Alt keys go to Neovim, not Zellij. Press `Ctrl g` to manually toggle Lock if needed.

### "I want to move a pane to a different position"

Use the default Zellij move mode (not customized). You can also close and re-split with `Alt x` then `Alt s`/`Alt v`.

### "I accidentally closed Zellij"

Sessions auto-persist. Run `zellij attach` to reconnect. Run `zellij list-sessions` to see available sessions.

### "I want to detach and come back later"

Press `Ctrl o` then `d` to detach. Or just close the terminal — `on_force_close` is set to "detach", so the session survives.

---

## Quick Reference

### Global Shortcuts (work in all modes except Locked)

| Key | Action |
|-----|--------|
| `Alt h/j/k/l` | Navigate panes (Vim-style) |
| `Alt 1-9` | Jump to tab |
| `Alt 0` | Toggle last tab |
| `Alt n` | New pane |
| `Alt s` | Split below |
| `Alt v` | Split right |
| `Alt x` | Close pane |
| `Alt z` | Zoom pane |
| `Alt w` | Toggle floating panes |
| `Alt f` | Float/embed toggle |
| `Alt Enter` | New tab |
| `Alt q` | Close tab |
| `Alt ,` / `Alt .` | Move tab left/right |
| `Alt =` / `Alt -` | Resize bigger/smaller |
| `Alt [` / `Alt ]` | Cycle layouts |
| `Alt e` | Edit scrollback in Neovim |
| `Ctrl s` | Enter Scroll mode |
| `Ctrl g` | Toggle Locked mode |

### Plugin Shortcuts

| Key | Plugin |
|-----|--------|
| `Alt o` | Session manager |
| `Alt p` | Monocle (file finder) |
| `Alt r` | Room (pane/tab switcher) |
| `Alt b` | Harpoon (bookmarks) |
| `Alt /` | Forgot (keybinding helper) |
| `Alt m` | Multitask (multi-pane commands) |

### Scroll Mode (`Ctrl s`)

| Key | Action |
|-----|--------|
| `j`/`k` | Line up/down |
| `d`/`u` | Half page down/up |
| `Ctrl f`/`Ctrl b` | Full page down/up |
| `g`/`G` | Top/bottom |
| `/` | Search |
| `e` | Edit in Neovim |
| `Esc`/`q` | Exit |
