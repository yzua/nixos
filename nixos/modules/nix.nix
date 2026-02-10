# Nix package manager configuration (flakes, GC, binary caches).
{ inputs, pkgConfig, ... }:

{
  # Mirror pkgConfig from flake.nix — nixosSystem evaluates its own nixpkgs instance
  nixpkgs.config = pkgConfig;

  nix = {
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    channel.enable = false;

    extraOptions = ''
      warn-dirty = false
    '';

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      auto-optimise-store = true;
      download-buffer-size = 262144000; # 250 MB

      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;
      sandbox-fallback = false;

      max-substitution-jobs = 8;
      http-connections = 25;

      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };

    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
