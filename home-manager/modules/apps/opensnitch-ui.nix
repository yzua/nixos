# OpenSnitch UI (system tray icon for network monitoring).
# Only enabled when the NixOS opensnitch daemon is expected to run.
# Disabled for desktop (opensnitch.enable = false in NixOS config).
{ hostname, ... }:
{
  services.opensnitch-ui.enable = hostname != "desktop";
}
