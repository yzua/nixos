# Yazi File Manager Guide

Yazi is a terminal file manager with image preview support, Lua plugins, and fast navigation. It integrates with your shell for seamless directory changes and uses your terminal's image protocols for previews.

---

## Starting Yazi

```bash
yazi                    # Open in current directory
yazi /path/to/dir       # Open in specific directory
y                       # Shell wrapper — cd's to Yazi's directory on exit
```

The `y` command is the recommended way to use Yazi. When you quit (`q`), your shell will automatically `cd` to wherever you navigated in Yazi.

---

## Navigation

| Key | What It Does |
|-----|-------------|
| `j` / `↓` | Move down |
| `k` / `↑` | Move up |
| `l` / `→` / `Enter` | Open file/enter directory |
| `h` / `←` / `Backspace` | Go to parent directory |
| `gg` | Go to first item |
| `G` | Go to last item |
| `Ctrl+u` | Page up |
| `Ctrl+d` | Page down |

---

## File Operations

### Opening Files

| Key | What It Does |
|-----|-------------|
| `Enter` / `l` | Open file with default app / enter directory |
| `o` | Open with selected opener |
| `Ctrl+Enter` | Open file interactively (choose app) |

Files open with your default apps (configured in MIME settings). The editor for text files is VS Code (set in constants).

### Selection

| Key | What It Does |
|-----|-------------|
| `Space` | Toggle selection on current item |
| `v` | Enter visual selection mode |
| `V` | Enter visual selection mode (line) |
| `Ctrl+a` | Select all |
| `Ctrl+r` | Invert selection |
| `Esc` | Clear selection |

### Copy, Move, Delete

| Key | What It Does |
|-----|-------------|
| `y` | Yank (copy) selected files |
| `x` | Cut selected files |
| `p` | Paste yanked/cut files |
| `P` | Paste with overwrite |
| `d` | Trash selected files |
| `D` | Permanently delete selected files |

### Create and Rename

| Key | What It Does |
|-----|-------------|
| `a` | Create file |
| `A` | Create directory |
| `r` | Rename file |
| `c` | Copy filename to clipboard |
| `C` | Copy file path to clipboard |

---

## Search and Filter

| Key | What It Does |
|-----|-------------|
| `/` | Search in current directory |
| `?` | Search backwards |
| `n` | Next search match |
| `N` | Previous search match |
| `f` | Filter (fuzzy search) |
| `Esc` | Clear filter |

---

## Tabs

| Key | What It Does |
|-----|-------------|
| `t` | Create new tab |
| `1`-`9` | Switch to tab N |
| `[` | Previous tab |
| `]` | Next tab |
| `Ctrl+c` | Close current tab |

---

## View Options

| Key | What It Does |
|-----|-------------|
| `.` | Toggle hidden files |
| `z` | Toggle preview |
| `Z` | Toggle preview (with image) |
| `s` | Sort by... (opens menu) |

### Sorting Options (after pressing `s`)

| Key | Sort By |
|-----|---------|
| `m` | Modified time |
| `M` | Modified time (reverse) |
| `c` | Created time |
| `C` | Created time (reverse) |
| `e` | Extension |
| `E` | Extension (reverse) |
| `a` | Alphabetically |
| `A` | Alphabetically (reverse) |
| `n` | Naturally (numbers handled correctly) |
| `N` | Naturally (reverse) |
| `s` | Size |
| `S` | Size (reverse) |

---

## Bookmarks and Marks

| Key | What It Does |
|-----|-------------|
| `m` | Create bookmark |
| `'` | Jump to bookmark |
| `"` | Delete bookmark |
| `~` | Go to home directory |
| `-` | Go to previous directory |

---

## Shell Integration

| Key | What It Does |
|-----|-------------|
| `:` | Open command prompt |
| `;` | Run shell command |
| `!` | Run shell command (block until done) |
| `S` | Open shell in current directory |

---

## Help

| Key | What It Does |
|-----|-------------|
| `~` | Open help menu |
| `?` | Show keybindings |

---

## Configuration Highlights

Your Yazi setup includes:

| Setting | Value |
|---------|-------|
| Show hidden files | Yes (enabled by default) |
| Sort order | Natural, directories first |
| Line mode | Size (shows file sizes) |
| Show symlinks | Yes |
| Preview max size | 1000x1000 pixels |
| Image quality | 75% |

---

## Image Previews

Yazi displays image previews using your terminal's image protocol (sixel or kitty). In Ghostty, images render directly in the terminal.

Supported preview types:
- **Images** — JPEG, PNG, GIF, WebP, SVG
- **Videos** — Thumbnails via ffmpegthumbnailer
- **PDFs** — Page previews via poppler
- **Archives** — File listing
- **Text files** — Syntax highlighted via bat

---

## Tips

1. **Use `y` instead of `yazi`.** The shell wrapper automatically `cd`s to your final directory when you quit.

2. **Preview panel.** The right panel shows file previews. Press `z` to toggle it off if you need more space.

3. **Quick navigation.** Type `/` to search, then `n`/`N` to jump between matches. Faster than scrolling.

4. **Bulk operations.** Select multiple files with `Space`, then yank (`y`) or cut (`x`) and paste (`p`) to move them in batch.

5. **Sort by modified.** Press `s` then `m` to sort by modification time — useful for finding recent files.

6. **Open with default app.** Just press `Enter` on any file. MIME types are configured to open files in the right app.

7. **Hidden files visible.** Hidden files are shown by default. Press `.` to toggle them off if needed.

---

## Configuration File

| File | What It Controls |
|------|-----------------|
| `home-manager/modules/terminal/tools/yazi.nix` | Yazi settings, openers, preview config |

To apply changes after editing: `just home` (rebuilds Home Manager configuration).

---

## Quick Reference

### Essential

| Key | Action |
|-----|--------|
| `y` (shell) | Launch with cd-on-exit |
| `h/j/k/l` | Navigate (vim-style) |
| `Enter` | Open / enter directory |
| `q` | Quit (cd to current dir) |
| `Space` | Toggle selection |

### File Operations

| Key | Action |
|-----|--------|
| `y` | Copy (yank) |
| `x` | Cut |
| `p` | Paste |
| `d` | Delete (trash) |
| `a` | Create file |
| `A` | Create directory |
| `r` | Rename |

### Search & Filter

| Key | Action |
|-----|--------|
| `/` | Search |
| `f` | Fuzzy filter |
| `n` / `N` | Next/previous match |

### View

| Key | Action |
|-----|--------|
| `.` | Toggle hidden files |
| `z` | Toggle preview |
| `s` | Sort menu |
