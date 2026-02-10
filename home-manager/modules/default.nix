# Home Manager modules aggregation.
{
  imports = [
    # Desktop environment
    ./niri # Niri compositor (scrollable tiling Wayland)
    ./noctalia # Noctalia Shell (bar, launcher, notifications, OSD)
    ./stylix.nix # Theming engine (Gruvbox base16, fonts, cursor, icons)
    ./qt.nix # Qt theming (Kvantum + Gruvbox)
    ./mime.nix # MIME type default application associations
    ./nautilus.nix # Nautilus (GNOME Files) dconf preferences

    # Terminal and shell
    ./terminal # Shell, terminal emulator, CLI tools
    ./shell.nix # Nix shell integration and dev tools

    # Development
    ./ai-agents # AI coding agents (Claude Code, OpenCode, Codex, Gemini)
    ./languages # Language tooling (Go, JS/TS, Python)
    ./lsp-servers.nix # Language servers for editors
    ./neovim # Neovim editor with LSP and plugins
    ./mise.nix # Mise polyglot runtime manager

    # Applications
    ./apps # App configs (OBS, Syncthing, KeePassXC)

    ./nixcord.nix # Discord (Vesktop + Vencord)
    ./activitywatch.nix # ActivityWatch app usage tracking
    ./opensnitch-ui.nix # OpenSnitch application firewall GUI

    # Security
    ./gpg.nix # GnuPG agent and key configuration
  ];
}
