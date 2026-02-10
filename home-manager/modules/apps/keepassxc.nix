# KeePassXC password manager — desktop entry and SSH agent environment.
# Binary is firejail-wrapped at system level (nixos/modules/sandboxing.nix).
# Native messaging host for browser integration is managed by KeePassXC itself
# (Settings → Browser Integration) — NOT declaratively, to avoid read-only symlink conflicts.
_:

{
  xdg.desktopEntries.keepassxc = {
    name = "KeePassXC";
    genericName = "Password Manager";
    comment = "Cross-platform password manager";
    exec = "keepassxc %f";
    icon = "keepassxc";
    terminal = false;
    categories = [
      "Utility"
      "Security"
    ];
    mimeType = [ "application/x-keepass2" ];
  };
}
