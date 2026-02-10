# Home Manager Modules

User-level configuration: programs, dotfiles, theming, desktop environment.
No custom options — modules directly configure `programs.*`, `services.*`, `home.*`.

---

## Module Hierarchy

```
modules/
├── ai-agents/          # AI coding agent config (Claude Code, OpenCode, Codex, Gemini CLI, oh-my-opencode)
│   ├── default.nix     # Module with programs.aiAgents options, MCP servers, logging
│   ├── config.nix      # Actual agent configuration values
│   └── log-analyzer.nix # AI agent log analysis and dashboard
├── apps/               # App configs (OBS, Syncthing, KeePassXC)
├── niri/               # Niri compositor (scrollable tiling Wayland)
│   ├── default.nix     # Import hub
│   ├── main.nix        # Compositor settings, window rules, autostart
│   ├── binds.nix       # Keybindings and scripts
│   ├── idle.nix        # Idle management (DPMS, lock)
│   └── lock.nix        # Screen locker
├── noctalia/           # Noctalia Shell (bar, launcher, notifications, lock, wallpaper, OSD)
│   └── default.nix     # Bar, launcher, notifications, lock screen, wallpaper, control center, dock, OSD
├── neovim/             # Neovim editor with LSP, completion, and modern plugins
│   ├── default.nix     # Plugin declarations, treesitter, Lua config loading
│   ├── lua/            # Lua configuration (options, keymaps, LSP, plugins)
│   └── plugins/        # Plugin-specific configs (wakatime)
├── languages/          # Language tooling (Go, JS, Python)
├── terminal/           # Shell and terminal
│   ├── ghostty.nix     # Ghostty terminal emulator
│   ├── zellij.nix      # Terminal multiplexer
│   ├── direnv.nix      # Per-directory environments
│   ├── zsh/            # Zsh + Oh My Zsh (oxide theme)
│   │   ├── default.nix # Main zsh config with setOptions, OMZ, initContent
│   │   └── aliases.nix # Shell aliases
│   └── tools/          # CLI tools (atuin, bat, btop, carapace, cava, eza, fzf, git, htop, lazygit, starship, yazi, zathura, zoxide)
├── activitywatch.nix   # ActivityWatch app usage tracking (Wayland)
├── browser-isolation.nix # Isolated browser profiles (work, personal, Tor)
├── gpg.nix             # GPG agent and keys
├── lsp-servers.nix     # Language servers for editors
├── mime.nix            # Default app associations
├── mise.nix            # Runtime version manager
├── nautilus.nix        # Nautilus (GNOME Files) dconf preferences
├── nixcord.nix         # Discord (Vesktop + Vencord) declarative config
├── opensnitch-ui.nix   # OpenSnitch application firewall GUI
├── qt.nix              # Qt theming (Kvantum + Gruvbox)
├── shell.nix           # Shell integration (direnv, nix-your-shell)
└── stylix.nix          # Theming engine (Gruvbox)
```

---

## Package Chunks (`../packages/`)

Packages live separately from modules. Each chunk returns a list:
```nix
# Each chunk signature:
{ pkgs, pkgsStable }: [ ... ]

# Aggregated in packages/default.nix:
builtins.concatLists (map (f: import f { inherit pkgs pkgsStable; }) chunks)
```

12 chunks: `applications`, `cli`, `custom/prayer` (Islamic prayer times), `development`, `gnome`, `multimedia`, `networking`, `niri`, `privacy`, `productivity`, `system-monitoring`, `utilities`.

**When adding packages**: pick the domain chunk, add to its list. Don't create new chunks unless new domain.

---

## Theming (Stylix)

- Base16 scheme: `gruvbox-dark-soft`
- Fonts: JetBrains Mono (mono), Noto Sans (sans), Noto Serif (serif)
- Cursor: Bibata-Modern-Classic (24px)
- Icons: Gruvbox-Plus-Dark
- GTK extra CSS: flat style, no rounded corners (177 lines custom CSS)

### Stylix-Exempt Modules
These manage their own theming (Stylix `autoEnable` disabled):
- Noctalia Shell

When adding a new program: Stylix auto-applies theme. Override only if custom styling needed.

---

## Configuration Patterns

### Program Config (most common)
```nix
programs.<tool> = {
  enable = true;
  settings = { ... };
};
```

### Service Config
```nix
services.<service> = {
  enable = true;
  settings = { ... };
};
```

### Home Files (dotfiles)
```nix
home.file.".config/app/config" = {
  text = ''...'';  # or source = ./path;
};
xdg.configFile."app/style.css".text = ''...'';
```

---

## Adding a New Module

1. Create `home-manager/modules/<name>.nix`
2. Add import with comment to `home-manager/modules/default.nix`
3. Use `programs.*` or `services.*` — do NOT define custom options
4. Run: `just modules && just lint && just format && just check && just home`

For subdirectory modules (e.g., new tool in `terminal/tools/`):
1. Create the `.nix` file in the subdirectory
2. Add import to that subdirectory's `default.nix`
3. Same validation pipeline

---

## Notes

- `home.nix` receives `{ inputs, homeStateVersion, user, gitConfig, pkgsStable, constants, hostname }` via `extraSpecialArgs` from flake
- `hostname` available for host-specific HM config
- `gitConfig` available for Git module configuration
- `constants` available from `shared/constants.nix` (terminal, editor, font, theme, keyboard)
- No custom options namespace — HM modules are simpler than NixOS modules
