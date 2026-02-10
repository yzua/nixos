# Niri scrollable tiling Wayland compositor.

{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.niri.nixosModules.niri ];

  # Add niri overlay for mesa compatibility
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable; # Provided by niri overlay
  };

  # XWayland compatibility via xwayland-satellite
  environment.systemPackages = [ pkgs.xwayland-satellite-stable ];

  # Security services for compositor
  security.polkit.enable = true;

  # Override niri-flake's KDE polkit agent — it crashes outside KDE with
  # "polkit_agent_listener_register_with_options: assertion 'POLKIT_IS_SUBJECT' failed".
  # Use polkit-gnome instead, which works reliably under any GTK-based compositor.
  systemd.user.services.niri-flake-polkit = {
    serviceConfig = lib.mkForce {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      # Wait for logind to register the graphical session (Type=wayland).
      # Without this, polkit-gnome exits with "No session for pid" because the
      # user manager session (Type=unspecified) doesn't satisfy polkit's check.
      ExecCondition = pkgs.writeShellScript "wait-for-graphical-session" ''
        for i in $(seq 1 30); do
          session_type=$(${pkgs.systemd}/bin/loginctl show-session \
            $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | \
              ${pkgs.gawk}/bin/awk '/seat0/ {print $1}') \
            --property=Type --value 2>/dev/null)
          [ "$session_type" = "wayland" ] && exit 0
          sleep 1
        done
        exit 1
      '';
      Restart = "on-failure";
      RestartSec = 5;
      RestartSteps = 5; # Gradually increase delay between restarts
      RestartMaxDelaySec = 60;
      Environment = [
        "XDG_SESSION_TYPE=wayland"
        "XDG_SESSION_DESKTOP=niri"
      ];
    };
  };

}
