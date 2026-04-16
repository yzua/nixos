# Terminal, Shell, and CLI Tools

Shell environment: Ghostty terminal + Zellij multiplexer + Zsh (Oh My Zsh) + declarative CLI tools (`tools/` + `tools/git/`).
One-file-per-tool pattern in `tools/`. No custom options — uses `programs.*` directly.

---

## Structure

```
terminal/
├── default.nix      # Import hub
├── ghostty.nix      # GPU-accelerated terminal (Wayland-native, shell integration)
├── zellij/          # Multiplexer (WASM plugins, layouts, custom keybinds)
│   ├── default.nix  # Import hub
│   ├── config.nix   # Keybinds, UI, behavior
│   ├── layouts.nix  # Layouts (default, dev, ai, monitoring)
│   └── plugins.nix  # WASM plugins (zjstatus, autolock, monocle, room, harpoon, forgot, multitask)
├── direnv.nix       # Per-directory environments (nix-direnv)
├── scripts.nix      # Custom script wrappers (currently `nvidia-fans`)
├── shell.nix        # Nix shell integration and dev tools
├── zsh/
│   ├── default.nix  # Zsh + OMZ (Starship prompt, 23 setOptions)
│   ├── aliases.nix  # Shell aliases
│   ├── config.nix   # Zsh settings and initialization
│   ├── functions.nix # Custom zsh functions (nix helpers, agent wrappers, aip)
│   └── local-vars.nix # Local shell variables
└── tools/           # CLI tools — one .nix file per tool
    ├── default.nix  # Import hub (15 tool entries including `git/`)
    ├── atuin.nix    # Shell history (fuzzy, secrets filter, sync disabled)
    ├── bat.nix      # Syntax-highlighting cat
    ├── btop.nix     # System monitor (GPU support)
    ├── carapace.nix # Multi-shell completions
    ├── cava.nix     # Audio visualizer
    ├── eza.nix      # Modern ls
    ├── fzf.nix      # Fuzzy finder (Gruvbox colors, Zsh integration)
    ├── gh.nix       # GitHub CLI
    ├── git/         # Git (identity from constants, GPG signing, aliases, hooks)
    │   ├── default.nix # Import hub
    │   ├── config.nix  # Git settings, aliases, includes, ignores
    │   └── hooks.nix   # Global hooks (secret scanning, conventional commits, GPG enforcement)
    ├── lazygit.nix  # Git TUI
    ├── mpv.nix      # Media player with Vim keybindings
    ├── starship.nix # Cross-shell prompt (Gruvbox, language indicators)
    ├── yazi.nix     # File manager (Lua plugins, image preview)
    ├── zathura.nix  # PDF viewer
    └── zoxide.nix   # Smart directory jumper
```

---

## Key Components

### Zsh (`zsh/`, 5 files)

- **Framework**: Oh My Zsh (Starship handles the prompt)
- **Plugins**: sudo, extract, copypath, copyfile, bgnotify, fzf-tab
- **Completions**: Carapace (not OMZ completions)
- **Privacy history**: 28 patterns filtered (tokens, passwords, API keys, SSH, sops commands)
- **Custom functions**: `aip` (multi-agent Zellij panes), agent wrappers (`claude_glm`, `opencode_glm`, `opencode_gemini`, `opencode_gpt`, `opencode_openrouter`, `opencode_sonnet`, `opencode_zen`)
- **Agent wrappers**: Load secrets from sops at runtime, launch agents with correct env vars

### Zellij (`zellij/`, 4 files)

- **Plugins** (7 WASM): zjstatus (bar), zellij-autolock, monocle, room, harpoon, zellij-forgot, multitask
- **Layouts** (4): default (terminal), dev (nvim + lazygit), ai (Claude + logs), monitoring (btop + nvtop)
- **Keybinds**: ~60 bindings, colored mode indicators (Gruvbox)
- **Integration**: Auto-attach on terminal launch, `zjstatus` bar with git/mode/tabs

### Git (`tools/git/`, 3 files)

- **Identity**: `constants.user.*` (name, email, signingKey, githubEmail)
- **Conditional email**: GitHub noreply email for github.com repos via `includeIf`
- **Signing**: GPG commit/tag signing enabled
- **Diff tool**: difftastic (structural diff)
- **Aliases**: Extensive set including `st`, `co`, `br`, `lg`, `amend`, `wip`, `undo`, and changelog helpers
- **Global hooks** (`hooks.nix`): Secret scanning (blocks commits with tokens/keys), conventional commit enforcement, GPG signature enforcement

---

## Conventions

- Each tool in `tools/` uses `programs.<tool>` with declarative settings
- Tools reference `constants` for theming/identity (git, fzf, yazi, starship)
- Gruvbox colors applied via Stylix auto-theming or manual `constants.color.*`
- Shell aliases defined per-tool; aggregated in zsh via `shellAliases`

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

## Adding a CLI Tool

1. Create `tools/<name>.nix`
2. Configure via `programs.<name>` or `home.packages`
3. Add import to `tools/default.nix` with inline comment
4. Run: `just modules && just lint && just format && just home`

## Adding a Zsh Function

1. Add to `zsh/functions.nix` (`programs.zsh.initContent`)
2. For aliases: add to `zsh/aliases.nix`
3. Run: `just home`

## Adding a Zellij Layout

1. Add to `zellij/layouts.nix` following the existing `xdg.configFile` pattern
2. Follow existing pattern: pane splits + plugin references
3. Run: `just home`
