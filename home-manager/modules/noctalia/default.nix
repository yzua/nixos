# Noctalia Shell desktop environment.

{
  constants,
  inputs,
  pkgs,
  ...
}:

let
  apiQuotaScript = pkgs.writeShellScript "api-quota-widget" (
    builtins.readFile ../../../scripts/ai/api-quota.sh
  );
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (import ./bar.nix { inherit pkgs apiQuotaScript; })
    ./settings.nix
  ];

  # Required for system tray icons (SNI protocol).
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell.enable = true;
}
