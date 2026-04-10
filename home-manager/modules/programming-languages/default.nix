# Programming languages configuration modules.

{
  imports = [
    ./python # Python toolchain, LSP servers, and aliases
    ./javascript # JS/TS tooling, LSP servers, and aliases
    ./go # Go toolchain, env vars, and aliases
    ./mise # Mise polyglot runtime manager
  ];
}
