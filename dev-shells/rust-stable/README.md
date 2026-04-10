## Rust stable

This is a minimal template for Rust development on the stable channel.

---

## Initialization

```bash
nix flake init -t "/home/yz/System/dev-shells#rust-stable"
```

## Usage

- `nix develop`: opens a shell with the stable Rust toolchain and related development tools
- `nix build` : builds the Rust project. Outputs the binary to `./result/bin/<name>`
- `nix run`: runs the Rust program.

## Included tools

- `cargo`, `rustc`, `clippy`, `rustfmt`, `pkg-config`
- `cargo-audit` (when Cargo.lock exists)

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [Nixpkgs Rust support](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md) - uses `pkgs.rustPlatform` from nixpkgs
3. [rust-section of language frameworks](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#cargo-features-cargo-features) - optional (use it for extending the template)
