# Nix flake for a Rust development template using stable toolchain.
{
  description = "Rust development template";

  inputs = {
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:

    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        toolchain = pkgs.rustPlatform;
      in
      rec {
        # Executed by `nix build`
        packages.default = toolchain.buildRustPackage {
          pname = "template";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          # For other makeRustPlatform features see:
          # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#cargo-features-cargo-features
        };

        # Executed by `nix run`
        apps.default = utils.lib.mkApp { drv = packages.default; };

        # Used by `nix develop`
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              (with toolchain; [
                cargo
                rustc
                rustLibSrc
              ])
              clippy
              rustfmt
              pkg-config
            ]
            ++ pkgs.lib.optionals (builtins.pathExists ./Cargo.lock) [
              # Include cargo-audit for security checks when Cargo.lock exists
              cargo-audit
            ];

          # Specify the rust-src path (many editors rely on this)
          RUST_SRC_PATH = "${toolchain.rustLibSrc}";

          shellHook = ''
            # Show helpful messages for common Rust project setup
            if [ ! -f Cargo.toml ]; then
              echo "⚠️  Warning: Cargo.toml not found. Initialize with: cargo init"
            fi

            if [ ! -f Cargo.lock ] && [ -f Cargo.toml ]; then
              echo "💡 Tip: Run 'cargo build' to generate Cargo.lock"
            fi

            if [ -f Cargo.toml ]; then
              echo "🦀 Rust development environment ready!"
              echo "   cargo build    # Build project"
              echo "   cargo check    # Check for errors"
              echo "   cargo clippy   # Lint code"
              echo "   cargo test     # Run tests"
            fi
          '';
        };
      }
    );
}
