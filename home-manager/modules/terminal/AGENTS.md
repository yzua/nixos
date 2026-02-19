# Terminal, Shell, and CLI Tools

Shell environment: Ghostty terminal + Zellij multiplexer + Zsh (Oh My Zsh) + 16 CLI tools.
One-file-per-tool pattern in `tools/`. No custom options — uses `programs.*` directly.

---

## Structure

```
terminal/
├── default.nix      # Import hub
├── ghostty.nix      # GPU-accelerated terminal (Wayland-native, shell integration)
├── zellij.nix       # Multiplexer (8 WASM plugins, 3 layouts, 100+ keybinds)
├── direnv.nix       # Per-directory environments (nix-direnv)
├── scripts.nix      # Custom scripts (ai-ask, ai-help, ai-commit, nvidia-fans)
├── shell.nix        # Nix shell integration and dev tools
├── zsh/
│   ├── default.nix  # Zsh + OMZ (oxide theme, 21 setOptions, 40+ functions)
│   └── aliases.nix  # Shell aliases
└── tools/           # CLI tools — one .nix file per tool
    ├── default.nix  # Import hub (16 tools)
    ├── atuin.nix    # Shell history (fuzzy, secrets filter, sync disabled)
    ├── bat.nix      # Syntax-highlighting cat
    ├── btop.nix     # System monitor (GPU support)
    ├── carapace.nix # Multi-shell completions
    ├── cava.nix     # Audio visualizer
    ├── eza.nix      # Modern ls
    ├── fzf.nix      # Fuzzy finder (Gruvbox colors, Zsh integration)
    ├── gh.nix       # GitHub CLI
    ├── git.nix      # Git (identity from constants, GPG signing, 30+ aliases, difftastic)
    ├── htop.nix     # Process viewer (legacy, btop preferred)
    ├── lazygit.nix  # Git TUI
    ├── starship.nix # Cross-shell prompt (Gruvbox, language indicators)
    ├── yazi.nix     # File manager (Lua plugins, image preview)
    ├── zathura.nix  # PDF viewer
    └── zoxide.nix   # Smart directory jumper
```

---

## Key Components

### Zsh (`zsh/default.nix`, 346 lines)

- **Framework**: Oh My Zsh with oxide theme
- **Plugins**: sudo, extract, copypath, copyfile, bgnotify, fzf-tab
- **Completions**: Carapace (not OMZ completions)
- **Privacy history**: 20+ patterns filtered (tokens, passwords, API keys, SSH, sops commands)
- **Custom functions** (40+): `nix-diff-gen`, `fix`, `nix-fix`, `qq`, `deep`, `oc-tmux`, `proj`, `mkcd`, agent wrappers (`claude_glm`, `oc-sops`, `opencode_gemini`)
- **Agent wrappers**: Load secrets from sops at runtime, launch agents with correct env vars

### Zellij (`zellij.nix`, 344 lines)

- **Plugins** (8 WASM): zjstatus (bar), autolock, monocle, room, harpoon, zellij-forgot, multitask
- **Layouts** (3): default (terminal), dev (nvim + lazygit), ai (Claude + logs), monitoring (btop + nvtop)
- **Keybinds**: 100+ bindings, colored mode indicators (Gruvbox)
- **Integration**: Auto-attach on terminal launch, `zjstatus` bar with git/mode/tabs

### Git (`tools/git.nix`)

- **Identity**: `constants.user.*` (name, email, signingKey, githubEmail)
- **Conditional email**: GitHub noreply email for github.com repos via `includeIf`
- **Signing**: GPG commit/tag signing enabled
- **Diff tool**: difftastic (structural diff)
- **Aliases**: 30+ (st, co, br, lg, amend, wip, undo, etc.)

---

## Conventions

- Each tool in `tools/` uses `programs.<tool>` with declarative settings
- Tools reference `constants` for theming/identity (git, fzf, yazi, starship)
- Gruvbox colors applied via Stylix auto-theming or manual `constants.color.*`
- Shell aliases defined per-tool; aggregated in zsh via `shellAliases`

---

## Adding a CLI Tool

1. Create `tools/<name>.nix`
2. Configure via `programs.<name>` or `home.packages`
3. Add import to `tools/default.nix` with inline comment
4. Run: `just modules && just lint && just format && just home`

## Adding a Zsh Function

1. Add to `zsh/default.nix` → `programs.zsh.initContent` section
2. For aliases: add to `zsh/aliases.nix`
3. Run: `just home`

## Adding a Zellij Layout

1. Add to `zellij.nix` → `xdg.configFile."zellij/layouts/<name>.kdl"`
2. Follow existing pattern: pane splits + plugin references
3. Run: `just home`
