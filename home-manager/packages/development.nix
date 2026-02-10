# Development tools, databases, and reverse engineering.
{ pkgs, pkgsStable, ... }:

let
  latest = with pkgs; [
    aider-chat # AI pair programming (fast-moving, needs latest)
    cargo
    cargo-nextest
    rustc
    rustfmt # Rust formatter (system-wide for conform.nvim)
    clippy # Rust linter (system-wide for outside devShells)
    uv # Python package manager; provides uvx for MCP servers
    zed-editor
  ];

  stable = with pkgsStable; [
    # API development
    bruno
    burpsuite

    # Build tools
    act # Run GitHub Actions locally in Docker
    docker-compose
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

    # Databases (postgresql provides psql client + libs for local dev)
    dbeaver-bin
    postgresql
    redis
    sqlite

    # Java
    openjdk21

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
    };
  };
}
