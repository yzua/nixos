# Dev Shell Templates

This directory provides reusable Nix flake templates for development shells.

## Available templates

- `bun`: Bun-based JavaScript/TypeScript environment
- `cpp`: C/C++ development environment
- `deno`: Deno runtime development environment
- `go`: Go development environment
- `nodejs`: Node.js JavaScript/TypeScript environment
- `python-venv`: Python shell with `venv` workflow
- `rust-nightly`: Rust nightly toolchain via Fenix
- `rust-stable`: Rust stable toolchain

## Quickstart

```bash
# Replace <name> with one of the template names above.
nix flake init -t "https://github.com/yzua/nixos-config/main?dir=dev-shells#<name>"
```

## Local template usage

```bash
# From any empty directory:
nix flake init -t "/home/yz/System/dev-shells#<name>"
nix develop
```

## Validation checklist

- `nix flake show ./dev-shells`
- `nix flake check --no-build` (for each initialized template)
- `nix develop -c '<tool> --version'` smoke tests per template
