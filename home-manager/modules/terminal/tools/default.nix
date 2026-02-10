# Imports all cli tools.

{
  imports = [
    ./atuin.nix # Shell history with full-text search and sync
    ./bat.nix # Syntax-highlighting cat replacement
    ./btop.nix # Modern system monitor with GPU support
    ./cava.nix # Audio visualizer
    ./carapace.nix # Multi-shell completions
    ./eza.nix # Modern ls replacement
    ./fzf.nix # Fuzzy finder with Zsh integration
    ./gh.nix # GitHub CLI with declarative settings
    ./git.nix # Git configuration with difftastic
    ./htop.nix # Process viewer (legacy — btop preferred)
    ./lazygit.nix # Git TUI
    ./starship.nix # Cross-shell prompt
    ./yazi.nix # Terminal file manager
    ./zathura.nix # PDF viewer
    ./zoxide.nix # Smart directory jumper
  ];
}
