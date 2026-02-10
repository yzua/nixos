# Nix flake for a TypeScript fullstack development environment.
{
  description = "TypeScript fullstack development template";

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
          buildInputs = with pkgs; [
            nodejs
            pnpm
            bun
            typescript
            typescript-language-server
            vscode-langservers-extracted
            eslint
            prettier
            biome
            esbuild
            tailwindcss-language-server
          ];

          env = {
            NODE_ENV = "development";
          };

          shellHook = ''
            if [ ! -f package.json ]; then
              echo "No package.json found. Initialize with:"
              echo "   pnpm init       # pnpm project"
              echo "   bun init        # Bun project"
              echo "   npm init -y     # npm project"
            else
              echo "TypeScript development environment ready!"
              echo "   pnpm dev        # Start dev server"
              echo "   pnpm test       # Run tests"
              echo "   pnpm build      # Build project"
              echo "   biome check     # Lint + format"
            fi
          '';
        };
      }
    );
}
