# Neovim Guide for VSCode Users

Welcome! This guide will help you transition from VSCode to Neovim. Don't panic — it's simpler than it looks. You already have a fully configured setup with LSP, autocompletion, file explorer, and fuzzy finder. This guide teaches you how to use it.

---

## Opening Neovim

```bash
nvim              # Open Neovim (empty buffer)
nvim filename     # Open a specific file
nvim .            # Open Neovim in the current directory (shows file explorer)
```

Since `defaultEditor = true` is set, `nvim` is your default `$EDITOR`. Commands like `git commit` will open Neovim automatically.

`vi` and `vim` are aliased to `nvim`, so they all work the same. `vimdiff` is also aliased to `nvim -d`.

---

## Modal Editing — The Big Difference

In VSCode, you're always in "typing mode". Neovim has **modes**. Think of them as different "stances":

| Mode | How to Enter | What It Does | VSCode Equivalent |
|------|-------------|--------------|-------------------|
| **Normal** | `Esc` | Navigate, delete, copy, paste, run commands | — (no equivalent) |
| **Insert** | `i`, `a`, `o` | Type text | Default VSCode typing |
| **Visual** | `v`, `V`, `Ctrl+v` | Select text | Click and drag / Shift+arrows |
| **Command** | `:` | Run commands (save, quit, search-replace) | Command palette (Ctrl+Shift+P) |

**The golden rule**: Press `Esc` to go back to Normal mode. Always. When in doubt, press `Esc`.

### Entering Insert Mode

| Key | What It Does |
|-----|-------------|
| `i` | Insert before cursor |
| `a` | Insert after cursor |
| `o` | Open new line below and insert |
| `O` | Open new line above and insert |
| `I` | Insert at beginning of line |
| `A` | Insert at end of line |

---

## The 10 Keybindings You Need to Survive

Learn these first. Everything else can wait.

| # | Key | What It Does | When to Use |
|---|-----|-------------|-------------|
| 1 | `Esc` | Back to Normal mode | When you're stuck, lost, or confused |
| 2 | `i` | Enter Insert mode | When you want to type text |
| 3 | `Ctrl+S` | Save file | After making changes |
| 4 | `:q` + Enter | Quit | When you're done |
| 5 | `Space f f` | Find files | Opening a file (like Ctrl+P in VSCode) |
| 6 | `Space e` | Toggle file explorer | Browsing project files (like sidebar) |
| 7 | `u` | Undo | Made a mistake |
| 8 | `Ctrl+R` | Redo | Undid too much |
| 9 | `/` + text + Enter | Search in file | Finding text (like Ctrl+F) |
| 10 | `gd` | Go to definition | Jump to where something is defined |

---

## Navigating Files

### File Explorer (Neo-tree — like VSCode sidebar)

| Key | What It Does |
|-----|-------------|
| `Space e` | Toggle the file explorer sidebar |

Inside Neo-tree:
- Use `j`/`k` or arrow keys to move up/down
- Press `Enter` to open a file or expand a folder
- Press `a` to create a new file
- Press `d` to delete a file
- Press `r` to rename a file
- Press `?` to see all Neo-tree keybindings

### Fuzzy Finder (Telescope — like Ctrl+P in VSCode)

| Key | What It Does |
|-----|-------------|
| `Space f f` | Find files by name (like Ctrl+P) |
| `Space f g` | Search file contents (like Ctrl+Shift+F) |
| `Space f b` | Switch between open files (buffers) |
| `Space f h` | Search help documentation |

Inside Telescope:
- Type to filter results
- Use `Ctrl+j`/`Ctrl+k` or arrow keys to move up/down
- Press `Enter` to open the selected file
- Press `Esc` to close Telescope

---

## LSP Features (IntelliSense)

Your setup has language servers for TypeScript, Rust, Zig, Lua, and Nix (configured in Neovim with `vim.lsp.enable`). Additional LSP servers for Bash, YAML, Svelte, Markdown, and TOML are installed system-wide for other editors. They provide the same features you're used to from VSCode:

| Key | What It Does | VSCode Equivalent |
|-----|-------------|-------------------|
| `gd` | Go to definition | F12 / Ctrl+Click |
| `gr` | Find all references | Shift+F12 |
| `K` | Hover documentation | Mouse hover |
| `Space r n` | Rename symbol | F2 |
| `Space c a` | Code actions (quick fixes) | Ctrl+. |
| `Space d` | Show error/warning details | Hover over squiggly line |
| `[d` | Jump to previous error | F8 (previous) |
| `]d` | Jump to next error | F8 |

### Autocompletion

Completions appear automatically as you type. Here's how to use them:

| Key | What It Does |
|-----|-------------|
| `Tab` | Select next completion item |
| `Shift+Tab` | Select previous completion item |
| `Enter` | Confirm selection |
| `Ctrl+Space` | Manually trigger completion |
| `Ctrl+E` | Dismiss completion menu |
| `Ctrl+B` / `Ctrl+F` | Scroll documentation up/down |

Completions come from multiple sources (shown in the menu):
- **LSP** — intelligent suggestions from the language server
- **Snippet** — code templates (type a prefix, press Tab to expand)
- **Buffer** — words from the current file
- **Path** — file system paths

---

## Searching

### Search in Current File

| Key | What It Does |
|-----|-------------|
| `/` + text + `Enter` | Search forward |
| `?` + text + `Enter` | Search backward |
| `n` | Jump to next match |
| `N` | Jump to previous match |
| `Esc` | Clear search highlight |

### Search Across All Files

| Key | What It Does |
|-----|-------------|
| `Space f g` | Live grep — search text in all project files |
| `Space f f` | Find files by name |

---

## Git Signs

The gutter (left edge) shows git changes:

| Symbol | Meaning |
|--------|---------|
| `+` | Added line |
| `~` | Changed line |
| `_` | Deleted line (shown on the line below) |
| `‾` | Deleted line (shown on the line above) |

---

## Formatting (conform.nvim)

Your setup has automatic format-on-save with proper formatter chains for each language:

| Language | Formatter |
|----------|-----------|
| JavaScript/TypeScript/JSON | Biome |
| Python | ruff_format |
| Go | gofumpt + golines |
| Nix | nixfmt |
| Rust | rustfmt |
| Lua | stylua |
| YAML/Markdown/HTML/CSS | Prettier |
| Zig | zigfmt |

### Manual Formatting

| Key | What It Does |
|-----|-------------|
| `Space f` | Format current buffer (async) |

Format-on-save is enabled with a 500ms timeout. If the formatter times out, it falls back to LSP formatting.

---

## Linting (nvim-lint)

Async linting runs automatically on save and insert-leave. Linters are configured per filetype:

| Language | Linter |
|----------|--------|
| JavaScript/TypeScript | biomejs |
| Python | ruff |
| Go | golangci-lint |
| Nix | statix |
| Bash/Shell | shellcheck |
| Markdown | markdownlint |

Lint errors appear as diagnostics in the gutter and can be navigated with `[d` / `]d`.

---

## Diagnostics List (trouble.nvim)

Trouble provides a pretty list for diagnostics, references, and quickfix items.

| Key | What It Does |
|-----|-------------|
| `Space x x` | Toggle workspace diagnostics |
| `Space x X` | Toggle buffer diagnostics |
| `Space c s` | Show document symbols |
| `Space c l` | Show LSP definitions/references (side panel) |
| `Space x L` | Toggle location list |
| `Space x Q` | Toggle quickfix list |

Inside Trouble:
- `j` / `k` — navigate items
- `Enter` / `Tab` — jump to item
- `o` — jump and close
- `q` — close
- `K` — hover preview
- `p` — preview without jumping
- `P` — toggle preview mode

---

## Surround (nvim-surround)

Quickly add, change, or delete surrounding characters (quotes, brackets, tags).

### Adding Surroundings

| Key | What It Does | Example |
|-----|-------------|---------|
| `ys{motion}{char}` | Add surrounding | `ysiw"` → surround word with `"` |
| `yss{char}` | Surround entire line | `yss)` → surround line with `()` |
| `yS{motion}{char}` | Add on new lines | `yS$}` → wrap to end of line in `{}` |
| `ySS{char}` | Surround line on new lines | `ySS}` → line in `{}` with newlines |
| `S{char}` (visual) | Surround selection | Select text, `S"` → wrap with `"` |

### Changing Surroundings

| Key | What It Does | Example |
|-----|-------------|---------|
| `cs{old}{new}` | Change surrounding | `cs"'` → change `"` to `'` |

### Deleting Surroundings

| Key | What It Does | Example |
|-----|-------------|---------|
| `ds{char}` | Delete surrounding | `ds"` → remove `"` around word |

Common characters: `"`, `'`, `` ` ``, `(`, `)`, `[`, `]`, `{`, `}`, `<`, `>`, `t` (HTML tags).

---

## Comments

| Key | What It Does |
|-----|-------------|
| `Ctrl+/` | Toggle comment on current line (like VSCode!) |
| `gcc` | Toggle comment on current line (Vim way) |
| Select lines + `gc` | Toggle comment on selected lines |

---

## Which-Key (Keybinding Helper)

Press `Space` and **wait**. A popup will appear showing all available keybindings that start with Space. This is your cheat sheet built right into the editor!

---

## Common "I'm Stuck" Solutions

### "I can't type anything!"
You're in Normal mode. Press `i` to enter Insert mode, then type.

### "How do I exit Neovim?"
Press `Esc` first (to ensure you're in Normal mode), then type `:q` and press `Enter`.

If you have unsaved changes:
- `:wq` — save and quit
- `:q!` — quit without saving (discard changes)

### "I accidentally pressed something weird and everything looks wrong"
Press `Esc` a few times, then press `u` to undo. Keep pressing `u` until things look right.

### "The screen split and I don't know where I am"
Press `Ctrl+h/j/k/l` to navigate between windows, or `:q` to close the current window.

### "There are red squiggly lines everywhere"
Those are diagnostics (errors/warnings) from the language server. Press `Space d` on a highlighted line to see the full error message. Press `]d` to jump to the next error.

### "How do I select text?"
Press `v` to start selecting character by character, or `V` to select whole lines. Use movement keys (h/j/k/l or arrow keys) to extend the selection. Press `y` to copy, `d` to delete, or `Esc` to cancel.

### "How do I copy/paste from outside Neovim?"
The clipboard is configured to use your system clipboard (wl-copy on Wayland). `y` copies to clipboard, `p` pastes from clipboard. Ctrl+Shift+V also works in most terminals.

### "My changes disappeared after closing!"
Undo history is persistent (saved to disk). Open the file again and press `u` to undo.

---

## Full Keybinding Cheat Sheet

### General

| Key | Mode | Action |
|-----|------|--------|
| `Space` | N | Leader key (prefix for commands) |
| `Ctrl+S` | N, I | Save file |
| `Space w` | N | Save file |
| `Space q` | N | Quit |
| `Esc` | N | Clear search highlight |
| `u` | N | Undo |
| `Ctrl+R` | N | Redo |

### Navigation

| Key | Mode | Action |
|-----|------|--------|
| `h` / `j` / `k` / `l` | N | Left / Down / Up / Right |
| `w` | N | Jump to next word |
| `b` | N | Jump to previous word |
| `gg` | N | Go to top of file |
| `G` | N | Go to bottom of file |
| `Ctrl+h/j/k/l` | N | Move between windows |
| `0` | N | Go to beginning of line |
| `$` | N | Go to end of line |

### File Explorer (Neo-tree)

| Key | Mode | Action |
|-----|------|--------|
| `Space e` | N | Toggle file explorer |

### Fuzzy Finder (Telescope)

| Key | Mode | Action |
|-----|------|--------|
| `Space f f` | N | Find files |
| `Space f g` | N | Live grep (search in files) |
| `Space f b` | N | Find buffers |
| `Space f h` | N | Help tags |

### LSP (Code Intelligence)

| Key | Mode | Action |
|-----|------|--------|
| `gd` | N | Go to definition |
| `gr` | N | Find references |
| `K` | N | Hover documentation |
| `Space r n` | N | Rename symbol |
| `Space c a` | N | Code actions |
| `Space d` | N | Show diagnostics |
| `[d` | N | Previous diagnostic |
| `]d` | N | Next diagnostic |

### Completion

| Key | Mode | Action |
|-----|------|--------|
| `Tab` | I | Next completion item |
| `Shift+Tab` | I | Previous completion item |
| `Enter` | I | Confirm completion |
| `Ctrl+Space` | I | Trigger completion |
| `Ctrl+E` | I | Dismiss completion |

### Editing

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl+/` | N, V | Toggle comment |
| `gcc` | N | Toggle line comment |
| `gc` | V | Toggle comment on selection |
| `J` | V | Move selection down |
| `K` | V | Move selection up |
| `<` / `>` | V | Indent left / right |
| `dd` | N | Delete line |
| `yy` | N | Copy line |
| `p` | N | Paste after cursor |
| `P` | N | Paste before cursor |

### Formatting & Linting

| Key | Mode | Action |
|-----|------|--------|
| `Space f` | N, V | Format buffer |
| (auto) | — | Format on save (500ms timeout) |
| (auto) | — | Lint on save and insert-leave |

### Diagnostics (Trouble)

| Key | Mode | Action |
|-----|------|--------|
| `Space x x` | N | Workspace diagnostics |
| `Space x X` | N | Buffer diagnostics |
| `Space c s` | N | Document symbols |
| `Space c l` | N | LSP definitions/references |
| `Space x L` | N | Location list |
| `Space x Q` | N | Quickfix list |

### Surround

| Key | Mode | Action |
|-----|------|--------|
| `ys{motion}{char}` | N | Add surrounding (e.g., `ysiw"`) |
| `yss{char}` | N | Surround entire line |
| `ds{char}` | N | Delete surrounding (e.g., `ds"`) |
| `cs{old}{new}` | N | Change surrounding (e.g., `cs"'`) |
| `S{char}` | V | Surround selection |

### Search

| Key | Mode | Action |
|-----|------|--------|
| `/text` | N | Search forward |
| `?text` | N | Search backward |
| `n` | N | Next match |
| `N` | N | Previous match |

Mode legend: **N** = Normal, **I** = Insert, **V** = Visual

---

## Tips for Your First Week

1. **Don't try to learn everything at once.** Use the 10 survival keybindings above and add one new trick per day.

2. **Keep this guide open.** Run `nvim ~/System/guides/NEOVIM-GUIDE.md` in a separate terminal.

3. **Use the mouse.** Yes, really. Mouse support is enabled. Click to place cursor, scroll to navigate. You can wean off it gradually.

4. **Press Space and wait.** Which-key will show you what's available. It's like a built-in cheat sheet.

5. **Use Telescope for everything.** `Space f f` to open files, `Space f g` to search text. You'll rarely need the file explorer once you get comfortable.

6. **Don't fight the modes.** The pattern is: `Esc` (go to Normal) → do something → `i` (go to Insert) → type. It becomes muscle memory within a few days.

7. **Relative line numbers are on.** The left gutter shows how many lines away each line is from your cursor. Use these numbers for quick jumps: `5j` moves 5 lines down, `12k` moves 12 lines up.

8. **Learn one motion at a time.** Start with `w` (next word), `b` (prev word), `gg` (top), `G` (bottom). Add `f` (find character), `%` (matching bracket) later.

9. **The dot command (`.`) repeats your last action.** Delete a word with `dw`, then press `.` to delete the next word. Powerful once you get it.

10. **`:help` is your friend.** Type `:help telescope` to read about telescope, `:help lua-guide` for Lua scripting, etc.

11. **It gets better fast.** The first 2-3 days feel slow. By week 2, you'll be faster than VSCode for many tasks. By month 2, you won't want to go back.
