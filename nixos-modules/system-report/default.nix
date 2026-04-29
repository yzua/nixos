# Unified system health reporting (hourly errors, daily full, weekly cleanup).

{
  imports = [
    ./_options.nix # modules-check: manual-helper Option definitions
    ./_config.nix # modules-check: manual-helper Script derivations, systemd services, and timers
  ];
}
