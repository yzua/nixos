# Noctalia Shell desktop environment.

{
  inputs,
  ...
}:

let
  apiQuotaScript = "bash ${../../../scripts/ai/api-quota}/api-quota.sh";
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (import ./bar.nix { inherit apiQuotaScript; })
    ./settings.nix
  ];

  # Required for system tray icons (SNI protocol).
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell.enable = true;
}
