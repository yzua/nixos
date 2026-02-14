# Nix flake for a Go development environment.
{
  description = "Go development template";

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
            go
            gopls
            golangci-lint
            gofumpt
            golines
            delve
            gotests
            go-tools
            air
            protobuf
            protoc-gen-go
            protoc-gen-go-grpc
          ];

          env = {
            GO111MODULE = "on";
          };

          shellHook = ''
            export GOPATH="$PWD/.go"
            export GOBIN="$GOPATH/bin"
            mkdir -p "$GOBIN"

            if [ ! -f go.mod ]; then
              echo "No go.mod found. Initialize with: go mod init <module-name>"
            else
              echo "Go development environment ready!"
              echo "   go run .           # Run project"
              echo "   go test ./...      # Run all tests"
              echo "   golangci-lint run  # Lint code"
              echo "   air                # Hot reload"
            fi
          '';
        };
      }
    );
}
