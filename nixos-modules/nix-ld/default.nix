# Nix-ld dynamic linker for running non-Nix binaries.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.nixLd = {
    enable = lib.mkEnableOption "nix-ld dynamic linker for running non-Nix binaries";
  };

  config = lib.mkIf config.mySystem.nixLd.enable {
    programs.nix-ld = {
      enable = true;
      libraries = import ./_libraries.nix { inherit pkgs; };
    };
  };
}
