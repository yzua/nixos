# Dev Shells

8 standalone Nix flakes providing per-language development environments. Not part of the main system flake — each is an independent template.

---

## Available Templates

| Template | Directory | Key Tools |
|----------|-----------|-----------|
| `python-venv` | `python-venv/` | venv, ruff, black, isort, pytest, jupyter, django, fastapi |
| `rust-stable` | `rust-stable/` | cargo, rustc, clippy, rustfmt, cargo-audit |
| `rust-nightly` | `rust-nightly/` | Fenix nightly toolchain, cargo, rust-src, clippy |
| `nodejs` | `nodejs/` | node, pnpm, yarn, typescript, prettier, eslint |
| `bun` | `bun/` | bun, typescript, biome |
| `deno` | `deno/` | deno |
| `go` | `go/` | go, gopls, golangci-lint, gofumpt, delve, air, protobuf |
| `cpp` | `cpp/` | gcc, cmake, gnumake, clang-tools, gdb, valgrind, cppcheck |

---

## Usage

```bash
# Initialize from template
nix flake init -t "/home/yz/System/dev-shells#python-venv"

# Enter dev shell
nix develop

# With direnv (automatic)
echo 'use flake' > .envrc && direnv allow
```

---

## Common Patterns

All dev-shell flakes follow the same structure:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = pkgs.mkShell {
        packages = [ ... ];
        shellHook = ''
          # Project detection + helpful messages
        '';
      };
    });
}
```

- Multi-platform via `flake-utils.lib.eachDefaultSystem`
- `shellHook` with project detection (checks for `package.json`, `go.mod`, `CMakeLists.txt`, etc.)
- Rust shells set `RUST_SRC_PATH` for editor support
- Python uses `venvShellHook` for automatic venv creation
- Go sets `GOPATH=.go` and `GOBIN`
- `.envrc` with `use flake` for direnv integration

---

## Adding a Dev Shell

1. Create `dev-shells/<lang>/flake.nix` following the pattern above
2. Add `.envrc` with `use flake`
3. Register template in `dev-shells/flake.nix` → `templates.<name>`
4. Test: `cd dev-shells/<lang> && nix develop`
