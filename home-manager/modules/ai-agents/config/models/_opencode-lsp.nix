# OpenCode LSP server configuration.

{
  bash = {
    command = [
      "bash-language-server"
      "start"
    ];
    extensions = [
      "sh"
      "bash"
      "zsh"
    ];
  };
  go = {
    command = [ "gopls" ];
    extensions = [ "go" ];
  };
  nix = {
    command = [ "nixd" ];
    extensions = [ "nix" ];
  };
  python = {
    command = [
      "pyright-langserver"
      "--stdio"
    ];
    extensions = [
      "py"
      "pyi"
    ];
  };
  typescript = {
    command = [
      "typescript-language-server"
      "--stdio"
    ];
    extensions = [
      "js"
      "jsx"
      "ts"
      "tsx"
      "mjs"
      "cjs"
    ];
  };
  json = {
    command = [
      "vscode-json-language-server"
      "--stdio"
    ];
    extensions = [
      "json"
      "jsonc"
    ];
  };
  yaml = {
    command = [
      "yaml-language-server"
      "--stdio"
    ];
    extensions = [
      "yaml"
      "yml"
    ];
  };
  clang = {
    command = [ "clangd" ];
    extensions = [
      "c"
      "cc"
      "cpp"
      "cxx"
      "h"
      "hpp"
    ];
  };
  rust = {
    command = [ "rust-analyzer" ];
    extensions = [ "rs" ];
  };
}
