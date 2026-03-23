# VNC remote access (x11vnc, noVNC, websockify).
# SECURITY: x11vnc defaults to NO encryption. Always tunnel through SSH or use
# the vnc-secure-startup launcher which forces localhost-only + SSH tunnel instructions.
{
  config,
  lib,
  pkgsStable,
  user,
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

    # Security wrapper: VNC only accessible via SSH tunnel
    environment.etc."vnc-security-readme.txt".text = ''
      VNC SECURITY INSTRUCTIONS
      =========================
      x11vnc transmits data UNENCRYPTED. Never expose it directly to the network.

      CORRECT USAGE (SSH tunnel):
        1. Start x11vnc on this host (localhost only):
           x11vnc -display :0 -localhost -rfbport 5900 -nopw -xkb

        2. From remote machine, create SSH tunnel:
           ssh -L 5900:localhost:5900 ${user}@<this-host-ip>

        3. Connect VNC viewer to localhost:5900

      noVNC WEB ACCESS (localhost only):
        websockify --web=${pkgsStable.novnc}/share/novnc 6080 localhost:5900
        Then open http://localhost:6080/vnc.html

      NEVER use -nopw without -localhost. NEVER expose port 5900/6080 to the internet.
    '';

    # Firewall: Block VNC ports from external access (SSH tunnel only)
    networking.firewall.extraCommands = ''
      # Block external VNC access — must use SSH tunnel
      iptables -A INPUT -p tcp --dport 5900 -s 127.0.0.1 -j ACCEPT
      iptables -A INPUT -p tcp --dport 5900 -j DROP
      iptables -A INPUT -p tcp --dport 6080 -s 127.0.0.1 -j ACCEPT
      iptables -A INPUT -p tcp --dport 6080 -j DROP
    '';
  };
}
