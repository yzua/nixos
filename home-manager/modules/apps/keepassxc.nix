# KeePassXC password manager — desktop entry.
# Native messaging host for browser integration is managed by KeePassXC itself
# (Settings → Browser Integration) — NOT declaratively, to avoid read-only symlink conflicts.

{ pkgs, ... }:

{
  xdg.desktopEntries.keepassxc = {
    name = "KeePassXC";
    genericName = "Password Manager";
    comment = "Cross-platform password manager";
    exec = "${pkgs.keepassxc}/bin/keepassxc %f";
    icon = "keepassxc";
    terminal = false;
    categories = [
      "Utility"
      "Security"
    ];
    mimeType = [ "application/x-keepass2" ];
  };
}
