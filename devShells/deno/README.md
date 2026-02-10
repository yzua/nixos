# Deno

This is a minimal template for JavasScript development with Deno.

## Initialization

```bash
nix flake init -t "github:82163/nixos-config/main?dir=devShells#deno"
```

## Usage

- `nix develop`: opens up a `bash` shell with the required packages
- `nix build` : builds the Deno project.
- `nix run`: runs the Deno program.

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [Deno](https://deno.land/) - used as JS and TS runtime
3. [Deno2Nix](https://github.com/SnO2WMaN/deno2nix) - used to convert Deno projects into Nix derivations
