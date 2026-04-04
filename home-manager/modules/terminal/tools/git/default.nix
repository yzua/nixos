# Git version control with enforced GPG signing, global hooks, and quality-of-life settings.

{
  imports = [
    ./hooks.nix # Global git hooks (secret scanning, conventional commits, GPG enforcement)
    ./config.nix # Git settings, aliases, includes, ignores
  ];
}
