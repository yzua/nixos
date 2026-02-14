# C/C++

Minimal C/C++ development template with common build and debugging tools.

## Initialization

```bash
nix flake init -t "github:82163/nixos-config/main?dir=dev-shells#cpp"
```

## Usage

- `nix develop`: opens a shell with C/C++ toolchain
- `cmake -B build . && cmake --build build`: CMake build flow
- `make`: Makefile build flow

## Included tools

- `gcc`, `cmake`, `gnumake`, `pkg-config`
- `clang-tools`, `cppcheck`, `gdb`, `valgrind`

## References

1. [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)
2. [Nixpkgs C/C++ tooling](https://github.com/NixOS/nixpkgs)
