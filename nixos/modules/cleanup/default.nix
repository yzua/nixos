{ lib, ... }:
{
  options.mySystem.cleanup.enable = lib.mkEnableOption "automated file and cache cleanup services";

  imports = [
    ./downloads.nix
    ./cache.nix
    # ./lib.nix (imported manually by submodules)
  ];
}
