# Obsidian Markdown notes app with a ready-to-use default vault.
{
  config,
  pkgs,
  ...
}:
let
  defaultVault = "Vault";
  defaultVaultPath = "${config.home.homeDirectory}/${defaultVault}";
in
{
  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    genericName = "Markdown Notes";
    comment = "Markdown knowledge base";
    exec = "${pkgs.obsidian}/bin/obsidian --vault ${defaultVaultPath} %U";
    icon = "obsidian";
    terminal = false;
    categories = [
      "Office"
      "Utility"
    ];
    mimeType = [
      "text/markdown"
      "x-scheme-handler/obsidian"
    ];
  };

  # Register default vault in Obsidian while keeping vault-local settings user-managed.
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;

    vaults.${defaultVault} = {
      target = defaultVault;
    };
  };
}
