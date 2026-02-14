# Nix flake for a Deno JavaScript application.
{
  description = "Deno Javascript App";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    deno2nix = {
      url = "github:SnO2WMaN/deno2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      utils,
      deno2nix,
    }:

    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ deno2nix.overlays.default ];
        };
      in
      rec {
        apps.default = utils.lib.mkApp { drv = packages.default; };

        packages.default = pkgs.deno2nix.mkExecutable {
          pname = "template";
          version = "0.1.0";
          src = ./.;
          lockfile = "./lock.json";
          config = "./deno.jsonc";
          entrypoint = "./src/index.ts";
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ deno ];

          shellHook = ''
            # Check for Deno configuration files
            if [ ! -f deno.json ] && [ ! -f deno.jsonc ] && [ ! -f deno.toml ]; then
              echo "⚠️  No Deno configuration file found. Create deno.json, deno.jsonc, or deno.toml"
              echo "   Example: deno.jsonc with { \"compilerOptions\": { \"allowJs\": true } }"
            else
              echo "🦕 Deno development environment ready!"
              echo "   deno run <file>     # Run TypeScript/JavaScript file"
              echo "   deno test           # Run tests"
              echo "   deno bench          # Run benchmarks"
              echo "   deno fmt            # Format code"
              echo "   deno lint           # Lint code"
            fi
          '';
        };
      }
    );
}
