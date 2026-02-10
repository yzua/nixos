# Terminal, shell, and CLI tool modules.
{
  imports = [
    ./tools # CLI tools (bat, eza, git, atuin, btop, yazi, starship, etc.)
    ./zsh # Zsh shell configuration
    ./ghostty.nix # Ghostty terminal emulator (GPU-accelerated, native Wayland)
    ./zellij.nix # Zellij terminal multiplexer
    ./direnv.nix # Per-directory environment loading
  ];
}
