## Rust stable

This is a minimal template for Rust development on the stable channel.

---

## Initialization

```bash
nix flake init -t "github:82163/nixos-config/main?dir=dev-shells#rust-stable"
```

## Usage

- `nix develop`: opens up a `bash` shell with the bare minimum Rust toolset (`cargo` & `rustc`) by default
- `nix build` : builds the Rust project. Outputs the binary to `./result/bin/<name>`
- `nix run`: runs the Rust program.

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [Fenix](https://github.com/nix-community/fenix) - used for managing Rust toolchains (read the `makeRustPlatform` example)
3. [rust-section of language frameworks](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#cargo-features-cargo-features) - optional (use it for extending the template)
