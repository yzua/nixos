# Nix package manager configuration (flakes, GC, binary caches, update notifications).

{
  inputs,
  lib,
  pkgConfig,
  pkgsStable,
  ...
}:

{
  # Mirror pkgConfig from flake.nix — nixosSystem evaluates its own nixpkgs instance
  nixpkgs.config = pkgConfig;

  nix = {
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    channel.enable = false;

    # Pin flake registry to our nixpkgs -- avoids network lookups for `nix run nixpkgs#<pkg>`
    registry.nixpkgs.flake = inputs.nixpkgs;

    extraOptions = ''
      warn-dirty = false
    '';

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      # SECURITY: Restrict Nix daemon access
      allowed-users = [ "@wheel" ];
      trusted-users = [
        "root"
        "@wheel"
      ];

      auto-optimise-store = true;
      download-buffer-size = 262144000; # 250 MB

      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;
      sandbox-fallback = false;

      max-jobs = "auto";
      cores = 0;
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

  # === Security Update Notification Timer ===
  # Daily reminder that updates should be checked. Does NOT auto-apply.
  # Run `just update && just nixos` manually when convenient.
  systemd.services.security-update-check = {
    description = "Log security update check timestamp";
    script = ''
      set -euo pipefail
      LOG=/var/log/security-update-check.log
      ${pkgsStable.coreutils}/bin/date -Iseconds >> "$LOG"
    '';
    serviceConfig = {
      Type = "oneshot";
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      NoNewPrivileges = true;
      ReadWritePaths = [ "/var/log" ];
    };
  };

  systemd.timers.security-update-check = {
    description = "Daily security update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
