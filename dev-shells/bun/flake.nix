# Nix flake for a Bun JavaScript application.
{
  description = "Bun Javascript App";

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
          name = "bun-app";
          buildInputs = with pkgs; [
            bun
            typescript
            typescript-language-server
            biome
          ];

          env = {
            NODE_ENV = "development";
          };

          shellHook = ''
            if [ ! -f package.json ]; then
              echo "No package.json found. Initializing Bun project..."
              bun init --yes
            else
              echo "Bun development environment ready!"
              echo "   bun install    # Install dependencies"
              echo "   bun run dev    # Start development server"
              echo "   bun build      # Build project"
              echo "   bun test       # Run tests"
              echo "   biome check    # Lint + format"
            fi
          '';
        };
      }
    );
}
