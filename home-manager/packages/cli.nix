# CLI tools for file management, text processing, and development.
# NOTE: fzf and carapace are managed by programs.* modules.
#       yt-dlp is firejail-wrapped at system level.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Backup
    borgbackup
    restic

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

    # Version control (gh managed by programs.gh in terminal/tools/gh.nix)
    git-absorb
    glab
    hcloud
    lazydocker
    serie
  ];
}
