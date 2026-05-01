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

| Key                 | What It Does               |
| ------------------- | -------------------------- |
| `j` / `↓`           | Move down                  |
| `k` / `↑`           | Move up                    |
| `l` / `→` / `Enter` | Open file/enter directory  |
| `h` / `←`           | Go to parent directory     |
| `gg`                | Go to first item           |
| `G`                 | Go to last item            |
| `H`                 | Back to previous directory |
| `L`                 | Forward to next directory  |
| `Ctrl+u`            | Move up half page          |
| `Ctrl+d`            | Move down half page        |
| `Ctrl+b`            | Move up full page          |
| `Ctrl+f`            | Move down full page        |

---

## File Operations

### Opening Files

| Key           | What It Does                                 |
| ------------- | -------------------------------------------- |
| `Enter` / `l` | Open file with default app / enter directory |
| `o`           | Open selected files                          |
| `O`           | Open selected files interactively            |

Files open with your default apps (configured in MIME settings). The editor for text files is VS Code (set in `constants.editor`); it opens as an external, non-blocking window.

### Selection

| Key      | What It Does                        |
| -------- | ----------------------------------- |
| `Space`  | Toggle selection on current item    |
| `Ctrl+a` | Select all                          |
| `Ctrl+r` | Invert selection                    |
| `v`      | Enter visual selection mode         |
| `V`      | Enter visual selection mode (unset) |
| `Esc`    | Clear selection                     |

### Copy, Move, Delete

| Key | What It Does                      |
| --- | --------------------------------- |
| `y` | Yank (copy) selected files        |
| `x` | Cut selected files                |
| `p` | Paste yanked/cut files            |
| `P` | Paste with overwrite              |
| `d` | Trash selected files              |
| `D` | Permanently delete selected files |

### Create and Rename

| Key | What It Does                                             |
| --- | -------------------------------------------------------- |
| `a` | Create file or directory (ends with `/` for directories) |
| `r` | Rename file                                              |

### Copy Path

| Key   | What It Does                    |
| ----- | ------------------------------- |
| `c c` | Copy file path                  |
| `c d` | Copy directory path             |
| `c f` | Copy filename                   |
| `c n` | Copy filename without extension |

---

## Find and Filter

| Key   | What It Does                |
| ----- | --------------------------- |
| `/`   | Find next file (fuzzy)      |
| `?`   | Find previous file (fuzzy)  |
| `n`   | Next found match            |
| `N`   | Previous found match        |
| `f`   | Filter files (smart)        |
| `Esc` | Clear filter or cancel find |

### Search

| Key | What It Does                     |
| --- | -------------------------------- |
| `s` | Search files by name (via fd)    |
| `S` | Search files by content (via rg) |

---

## Tabs

| Key     | What It Does           |
| ------- | ---------------------- |
| `t t`   | Create new tab in CWD  |
| `t r`   | Rename current tab     |
| `1`-`9` | Switch to tab N        |
| `[`     | Previous tab           |
| `]`     | Next tab               |
| `{`     | Swap with previous tab |
| `}`     | Swap with next tab     |

---

## View Options

| Key | What It Does                 |
| --- | ---------------------------- |
| `.` | Toggle hidden files          |
| `K` | Seek up 5 units in preview   |
| `J` | Seek down 5 units in preview |

### Jump

| Key | What It Does                   |
| --- | ------------------------------ |
| `z` | Jump to file/directory via fzf |
| `Z` | Jump to directory via zoxide   |

### Sorting

| Key   | Sort By                               |
| ----- | ------------------------------------- |
| `, m` | Modified time                         |
| `, M` | Modified time (reverse)               |
| `, b` | Birth time                            |
| `, B` | Birth time (reverse)                  |
| `, e` | Extension                             |
| `, E` | Extension (reverse)                   |
| `, a` | Alphabetically                        |
| `, A` | Alphabetically (reverse)              |
| `, n` | Naturally (numbers handled correctly) |
| `, N` | Naturally (reverse)                   |
| `, s` | Size                                  |
| `, S` | Size (reverse)                        |
| `, r` | Random                                |

### Linemode

| Key   | What It Shows |
| ----- | ------------- |
| `m s` | File size     |
| `m p` | Permissions   |
| `m b` | Birth time    |
| `m m` | Modified time |
| `m o` | Owner         |
| `m n` | None (clear)  |

### Go To

| Key       | What It Does                                  |
| --------- | --------------------------------------------- |
| `g h`     | Go to home directory                          |
| `g c`     | Go to `~/.config`                             |
| `g d`     | Diff selected file with hovered file (custom) |
| `g Space` | Jump interactively                            |
| `g f`     | Follow hovered symlink                        |

---

## Shell Integration

| Key | What It Does                         |
| --- | ------------------------------------ |
| `;` | Run shell command (interactive)      |
| `:` | Run shell command (block until done) |

---

## Help

| Key   | What It Does |
| ----- | ------------ |
| `~`   | Open help    |
| `F1`  | Open help    |
| `Esc` | Close help   |

---

## Configuration Highlights

Your Yazi setup includes:

| Setting           | Value                      |
| ----------------- | -------------------------- |
| Show hidden files | Yes (enabled by default)   |
| Sort order        | Natural, directories first |
| Line mode         | Size (shows file sizes)    |
| Show symlinks     | Yes                        |
| Preview max size  | 1000x1000 pixels           |
| Image quality     | 75%                        |

### Installed Plugins

| Plugin        | Purpose                                 |
| ------------- | --------------------------------------- |
| `git`         | Git status indicators in file list      |
| `diff`        | Diff selected file against hovered file |
| `full-border` | Border around file panels               |

### Custom Keybinds

| Key          | What It Does                                                 |
| ------------ | ------------------------------------------------------------ |
| `g` then `d` | Diff selected file against hovered file (uses `diff` plugin) |

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

2. **Preview panel.** Press `K`/`J` to seek up/down in the preview of the hovered file.

3. **Quick navigation.** Type `/` to find, then `n`/`N` to jump between matches. Faster than scrolling.

4. **Bulk operations.** Select multiple files with `Space`, then yank (`y`) or cut (`x`) and paste (`p`) to move them in batch.

5. **Sort by modified.** Press `,` then `m` to sort by modification time — useful for finding recent files.

6. **Open with default app.** Just press `Enter` on any file. MIME types are configured to open files in the right app.

7. **Hidden files visible.** Hidden files are shown by default. Press `.` to toggle them off if needed.

8. **Quick jump.** Press `z` to fuzzy-find a file via fzf, or `Z` to jump to a frequently-visited directory via zoxide.

---

## Configuration File

| File                                           | What It Controls                       |
| ---------------------------------------------- | -------------------------------------- |
| `home-manager/modules/terminal/tools/yazi.nix` | Yazi settings, openers, preview config |

To apply changes after editing: `just home` (rebuilds Home Manager configuration).

---

## Quick Reference

### Essential

| Key         | Action                   |
| ----------- | ------------------------ |
| `y` (shell) | Launch with cd-on-exit   |
| `h/j/k/l`   | Navigate (vim-style)     |
| `Enter`     | Open / enter directory   |
| `q`         | Quit (cd to current dir) |
| `Space`     | Toggle selection         |
| `~`         | Open help                |

### File Operations

| Key | Action          |
| --- | --------------- |
| `y` | Copy (yank)     |
| `x` | Cut             |
| `p` | Paste           |
| `d` | Delete (trash)  |
| `a` | Create file/dir |
| `r` | Rename          |

### Find & Filter

| Key       | Action              |
| --------- | ------------------- |
| `/`       | Find next           |
| `?`       | Find previous       |
| `f`       | Filter (smart)      |
| `n` / `N` | Next/previous found |

### View

| Key | Action              |
| --- | ------------------- |
| `.` | Toggle hidden files |
| `,` | Sort prefix         |
| `z` | Jump via fzf        |
