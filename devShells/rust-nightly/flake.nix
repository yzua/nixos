# Nix flake for a Rust development template using nightly toolchain (Fenix).
{
  description = "Rust development template using fenix";

  inputs = {
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      fenix,
      ...
    }:

    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ fenix.overlays.default ];
        };
        toolchain = pkgs.fenix.complete;
      in
      rec {
        # Executed by `nix build`
        packages.default =
          (pkgs.makeRustPlatform {
            # Use nightly rustc and cargo provided by fenix for building
            inherit (toolchain) cargo rustc;
          }).buildRustPackage
            {
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
          # Use nightly cargo & rustc provided by fenix. Add for packages for the dev shell here
          buildInputs =
            with pkgs;
            [
              (with toolchain; [
                cargo
                rustc
                rust-src
                clippy
                rustfmt
              ])
              pkg-config
            ]
            ++ pkgs.lib.optionals (builtins.pathExists ./Cargo.lock) [
              # Include cargo-audit for security checks when Cargo.lock exists
              cargo-audit
            ];

          # Specify the rust-src path (many editors rely on this)
          RUST_SRC_PATH = "${toolchain.rust-src}/lib/rustlib/src/rust/library";

          shellHook = ''
            # Show helpful messages for Rust nightly project setup
            if [ ! -f Cargo.toml ]; then
              echo "⚠️  Warning: Cargo.toml not found. Initialize with: cargo init"
            fi

            if [ ! -f Cargo.lock ] && [ -f Cargo.toml ]; then
              echo "💡 Tip: Run 'cargo build' to generate Cargo.lock"
            fi

            if [ -f Cargo.toml ]; then
              echo "🦀 Rust nightly development environment ready!"
              echo "   cargo build    # Build project with nightly"
              echo "   cargo check    # Check for errors"
              echo "   cargo clippy   # Lint code"
              echo "   cargo test     # Run tests"
              echo "   rustup override set nightly  # Ensure nightly toolchain"
            fi
          '';
        };
      }
    );
}
