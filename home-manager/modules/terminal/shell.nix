# Shell integration and Nix development tools.
{ pkgs, ... }:

{
  programs.nix-your-shell.enable = true;

  home.packages = with pkgs; [
    nixfmt
    statix
    deadnix
    nixd
    nix-tree
    nix-output-monitor
    cachix
    nix-init # Generate Nix packages from URLs
    nurl # Nix URL fetcher hash helper
  ];
}
