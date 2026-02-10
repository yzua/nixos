# KeePassXC password manager — desktop entry, browser integration, Secret Service, SSH agent.
# Binary is firejail-wrapped at system level (nixos/modules/sandboxing.nix).
{ pkgsStable, ... }:

let
  proxyBin = "${pkgsStable.keepassxc}/bin/keepassxc-proxy";
in
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

  # Native messaging host for KeePassXC-Browser extension (Brave/Chromium)
  home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json".text =
    builtins.toJSON {
      name = "org.keepassxc.keepassxc_browser";
      description = "KeePassXC Browser Integration";
      path = proxyBin;
      type = "stdio";
      allowed_origins = [
        "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
      ];
    };
}
