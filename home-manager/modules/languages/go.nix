# Go development environment (gopls, delve, golangci-lint, etc).

{
  config,
  pkgs,
  ...
}:

{
  programs = {
    go = {
      enable = true;
      package = pkgs.go;

      env = {
        GOPATH = "go";
        GOBIN = "go/bin";
        GOPRIVATE = [ ];
      };
    };

    zsh.shellAliases = {
      gorun = "go run";
      gobuild = "go build";
      gotest = "go test -v";
      gomod = "go mod";
      gofmt = "gofumpt -w";
      golint = "golangci-lint run";
      goair = "air";
      godebug = "dlv debug";
      gotrace = "dlv trace";
    };

    git.ignores = [
      "*.exe"
      "*.exe~"
      "*.dll"
      "*.so"
      "*.dylib"
      "*.test"
      "go.work"
      "go.work.sum"
    ];
  };

  home = {
    packages = with pkgs; [
      gopls
      go-tools
      delve
      golangci-lint
      air
      gofumpt
      golines
      gotests
      impl
      gomodifytags
      govulncheck
      go-migrate
      sqlc
      protobuf
      protoc-gen-go
      protoc-gen-go-grpc
    ];

    # GOPATH and GOBIN are set by programs.go.env above
    sessionVariables = {
      GO111MODULE = "on";
      GOPROXY = "https://proxy.golang.org,direct";
      GOSUMDB = "sum.golang.org";
    };

    sessionPath = [
      "${config.home.homeDirectory}/go/bin"
    ];

    # Go creates ~/go/{bin,pkg,src} on demand — no activation needed
  };
}
