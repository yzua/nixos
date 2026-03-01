# Development tools, databases, and reverse engineering.
{ pkgs, pkgsStable, ... }:

let
  latest = with pkgs; [
    aider-chat # AI pair programming (fast-moving, needs latest)
    cargo
    cargo-nextest
    rustc
    rustfmt # Rust formatter (system-wide for conform.nvim)
    zig # Zig compiler + formatter (used by AI agent hooks and editors)
    clippy # Rust linter (system-wide for outside dev-shells)
    nixfmt # Nix formatter
    statix # Nix linter
    deadnix # Nix dead code detector
    nixd # Nix language server
    nix-tree # Nix dependency explorer
    nix-output-monitor # Better Nix build output
    cachix # Binary cache client
    nix-init # Generate Nix packages from URLs
    nurl # Nix URL fetcher hash helper
    uv # Python package manager; provides uvx for MCP servers
    dolt # Version-controlled SQL database (Beads backend)
  ];

  stable = with pkgsStable; [
    # API development
    bruno
    burpsuite
    hurl # HTTP request runner with assertions (CI-friendly API testing)
    grpcurl # CLI for gRPC services (reflection + file descriptor support)

    # Build tools
    act # Run GitHub Actions locally in Docker
    docker-compose
    earthly # Reproducible CI builds (Dockerfile + Makefile hybrid)
    git-lfs
    just
    pandoc
    repomix # Bundle repo into single file for AI context windows

    # C/C++ development
    cmake
    gcc
    gdb
    gnumake
    ltrace
    strace
    valgrind

    # Container tools
    skopeo # Container image inspection and copy (no daemon needed)

    # Databases (postgresql provides psql client + libs for local dev)
    dbeaver-bin
    pgcli # Auto-completing PostgreSQL CLI (drop-in psql replacement)
    litecli # Auto-completing SQLite CLI
    postgresql
    redis
    sqlite

    # Documentation
    d2 # Declarative diagramming language (text -> SVG)
    mdbook # Book generator from Markdown (Rust/Nix ecosystem standard)
    typst # Modern typesetting system (fast LaTeX alternative)

    # Java
    openjdk21

    # Linters
    hadolint # Dockerfile best practices linter
    shellcheck # Shell script static analysis (required by nvim-lint)

    # Profiling
    heaptrack # Heap memory profiler (allocation tracking + GUI)
    tokio-console # Real-time async Rust (tokio) diagnostics

    # Reverse engineering (android-tools provided by nixos/modules/android.nix)
    apktool
    binwalk
    cutter
    frida-tools
    ghidra-bin
    jadx
    radare2

    # Rust development
    bacon
    cargo-deny
    cargo-tarpaulin # Rust code coverage
    cargo-watch

    # C/C++ static analysis
    cppcheck

    # Shell scripting
    bats # Bash testing framework
    shfmt # Shell script formatter

    # Build acceleration
    sccache # Shared compilation cache (Rust/C++)

    # Dev orchestration
    process-compose # Multi-service dev orchestrator
  ];
in
{
  home = {
    packages = latest ++ stable;

    sessionVariables = {
      RUSTC_WRAPPER = "sccache"; # Use sccache for faster Rust/C++ rebuilds
      DOCKER_CONTENT_TRUST = "1"; # SECURITY: Enforce signed Docker images
    };
  };
}
