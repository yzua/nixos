# OpenSnitch UI (system tray icon for network monitoring).
# Disabled while the NixOS opensnitch daemon is disabled.
_: {
  services.opensnitch-ui.enable = false;
}
