# Custom utility scripts added to user PATH.
{ pkgs, user, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "nvidia-fans" ''
      exec /home/${user}/System/scripts/nvidia-fans.sh "$@"
    '')
  ];
}
