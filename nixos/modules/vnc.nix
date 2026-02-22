# VNC remote access (x11vnc, noVNC, websockify).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.vnc = {
    enable = lib.mkEnableOption "VNC remote access with x11vnc, noVNC, and websockify";
  };

  config = lib.mkIf config.mySystem.vnc.enable {
    environment.systemPackages = with pkgs; [
      x11vnc
      novnc
      python3Packages.websockify
    ];
  };
}
