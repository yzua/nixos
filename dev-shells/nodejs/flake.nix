# Nix flake for a Node.js application.
{
  description = "NodeJS Javascript App";

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
          name = "nodejs-app";
          buildInputs = with pkgs; [
            nodejs
            pnpm
            yarn
            typescript
            typescript-language-server
            prettier
            eslint
          ];

          env = {
            NODE_ENV = "development";
          };

          shellHook = ''
            if [ ! -f package.json ]; then
              npm init -y
            else
              echo "Node.js development environment ready!"
              echo "   npm run dev     # Start dev server"
              echo "   npm test        # Run tests"
              echo "   npm run build   # Build project"
            fi
          '';
        };
      }
    );
}
