# Go

Minimal Go development template with linting, debugging, and protobuf tooling.

## Initialization

```bash
nix flake init -t "github:yzua/nixos/master?dir=dev-shells#go"
```

## Usage

- `nix develop`: opens a shell with Go tooling
- `go mod init <module-name>`: initialize module when starting a new project
- `go test ./...`: run all tests
- `golangci-lint run`: run linter

## Included tools

- `go`, `gopls`, `golangci-lint`, `gofumpt`
- `delve`, `air`, `gotests`, `go-tools`
- `protobuf`, `protoc-gen-go`, `protoc-gen-go-grpc`

## References

1. [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)
2. [Go documentation](https://go.dev/doc/)
