# Custom utility scripts added to user PATH.
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "nvidia-fans" ''
      exec ${config.home.homeDirectory}/System/scripts/nvidia-fans.sh "$@"
    '')
  ];
}
