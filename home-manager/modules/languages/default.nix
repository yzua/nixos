# Programming languages configuration modules.

{
  imports = [
    ./go.nix # Go toolchain, env vars, and aliases
    ./javascript.nix # JS/TS tooling, LSP servers, and aliases
    ./python.nix # Python tooling, LSP servers, and aliases
  ];
}
