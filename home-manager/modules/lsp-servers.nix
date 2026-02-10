# Language servers for editor integration.

{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # High Priority (Python packages handled in python.nix)
    nil # Nix language server
    bash-language-server # Bash scripts (scripts/ directory)
    nodePackages.yaml-language-server # YAML configs
    nodePackages.svelte-language-server # Svelte framework
    pyright # Python type-checking LSP (completions + diagnostics)
    clang-tools # C/C++ LSP (clangd) + formatter (clang-format)

    # Medium Priority
    rust-analyzer # Rust support
    lua-language-server # Lua configs
    marksman # Markdown docs
    markdownlint-cli # Markdown linting (used by nvim-lint)

    # Specialized
    taplo # TOML files (Cargo.toml, pyproject.toml, justfile)
  ];
}
