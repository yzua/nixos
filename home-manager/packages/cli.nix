# CLI tools for file management, text processing, and development.
# NOTE: fzf and carapace are managed by programs.* modules.
# NOTE: restic managed by services.restic
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Backup (restic managed by services.restic)
    borgbackup

    # Container analysis
    dive

    # Data formats
    fx

    # Documentation
    glow
    tealdeer

    # File and directory management
    duf
    dust
    fd
    fselect
    trash-cli # Safe rm replacement

    # General utilities
    actionlint
    bc
    codespell
    rsync
    typos
    watchexec

    # HTTP client
    xh

    # Log processing
    angle-grinder

    # Media processing
    imagemagick
    yt-dlp

    # Network analysis
    mitmproxy
    wireshark-cli

    # Nix tooling
    nix-diff # Derivation-level diff between NixOS generations
    nvd

    # Performance and benchmarking
    flamegraph
    hyperfine

    # Shell UI
    gum

    # System information
    fastfetch
    microfetch
    onefetch
    procs
    tokei

    # Terminal effects
    cmatrix
    peaclock

    # Terminal theming
    vivid

    # Text processing and search
    choose
    htmlq
    jq
    ripgrep
    ast-grep
    semgrep
    sd
    yq

    # Shell tools
    navi # Interactive cheatsheet browser with fzf

    # Terminal multiplexer
    tmux

    # Version control (gh managed by programs.gh in terminal/tools/gh.nix)
    git-absorb
    git-branchless # Stacked diffs, smartlog, undo for git
    git-cliff # Auto-generate changelogs from conventional commits
    git-crypt # Transparent file encryption in repos
    git-extras # 60+ git utilities (git-summary, git-effort, git-standup, etc.)
    git-interactive-rebase-tool # Better interactive rebase UI
    glab
    hcloud
    lazydocker
    serie
  ];
}
