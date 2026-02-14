# TypeScript

Minimal fullstack TypeScript development template with common JS/TS tooling.

## Initialization

```bash
nix flake init -t "github:82163/nixos-config/main?dir=dev-shells#typescript"
```

## Usage

- `nix develop`: opens a shell with TypeScript tooling
- `pnpm init` or `npm init -y`: initialize project
- `pnpm test`: run tests
- `biome check .`: lint and formatting checks

## Included tools

- `nodejs`, `pnpm`, `bun`
- `typescript`, `typescript-language-server`
- `eslint`, `prettier`, `biome`
- `esbuild`, `tailwindcss-language-server`

## References

1. [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)
2. [TypeScript docs](https://www.typescriptlang.org/docs/)
