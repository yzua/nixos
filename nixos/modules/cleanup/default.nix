# Automated file and cache cleanup services.
{ lib, ... }:
{
  options.mySystem.cleanup.enable = lib.mkEnableOption "automated file and cache cleanup services";

  imports = [
    ./downloads.nix
    ./cache.nix
    # ./_lib.nix (imported manually by submodules)
  ];
}
