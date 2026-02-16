# KeePassXC password manager — desktop entry and SSH agent environment.
# Binary is NOT firejail-wrapped (excluded in nixos/modules/sandboxing.nix).
# Native messaging host for browser integration is managed by KeePassXC itself
# (Settings → Browser Integration) — NOT declaratively, to avoid read-only symlink conflicts.
{ pkgsStable, ... }:

{
  xdg.desktopEntries.keepassxc = {
    name = "KeePassXC";
    genericName = "Password Manager";
    comment = "Cross-platform password manager";
    exec = "${pkgsStable.keepassxc}/bin/keepassxc %f";
    icon = "keepassxc";
    terminal = false;
    categories = [
      "Utility"
      "Security"
    ];
    mimeType = [ "application/x-keepass2" ];
  };
}
