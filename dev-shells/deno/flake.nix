# Nix flake for a Deno JavaScript application.
{
  description = "Deno Javascript App";

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
      in
      {
        devShells.default = pkgs.mkShell {
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
