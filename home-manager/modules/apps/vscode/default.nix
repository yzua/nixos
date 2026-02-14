# VS Code editor with declarative extensions and writable settings.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./extensions.nix # Extensions (nixpkgs + marketplace)
    ./activation.nix # Activation script (writes mutable settings.json)
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs; # Unstable channel — latest VS Code for extension compat

    # Fully declarative — only listed extensions are installed
    mutableExtensionsDir = true;

    profiles.default = {
      # NOTE: enableUpdateCheck and enableExtensionUpdateCheck are NOT set here
      # because they cause HM to generate a read-only settings.json symlink,
      # conflicting with the writable copy from the activation script below.
      # Equivalent settings are in settingsJson: "update.mode" = "none",
      # "extensions.autoCheckUpdates" = false, "extensions.autoUpdate" = false.
    };
  };
}
