# VNC remote access (x11vnc, noVNC, websockify).
{
  config,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.vnc = {
    enable = lib.mkEnableOption "VNC remote access with x11vnc, noVNC, and websockify";
  };

  config = lib.mkIf config.mySystem.vnc.enable {
    environment.systemPackages = with pkgsStable; [
      x11vnc
      novnc
      python3Packages.websockify
      xclip # X11 clipboard access (useful for VNC sessions)
    ];
  };
}
