# greetd display manager with tuigreet TUI greeter.

{
  config,
  lib,
  pkgsStable,
  systemdHelpers,
  ...
}:

let
  inherit (systemdHelpers) mkServiceHardening;
in
{
  options.mySystem.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
  };

  config = lib.mkIf config.mySystem.greetd.enable {
    services.greetd = {
      enable = true;
      package = pkgsStable.greetd;
      settings.default_session = {
        command = "${pkgsStable.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
        user = "greeter";
      };
    };
    # Avoid noisy gkr-pam warnings on greetd auth attempts; keyring is started in user session.
    security.pam.services.greetd.enableGnomeKeyring = lib.mkForce false;

    # Suppress duplicate login messages on tty1
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    }
    # SECURITY: Systemd hardening directives (mkForce to override upstream defaults)
    # PrivateDevices must be false — greetd needs access to the real /dev/tty*
    # for StandardInput=tty to work. PrivateDevices creates a private /dev
    # namespace that blocks TTY access, causing exit code 208 (STDIN EPERM).
    // mkServiceHardening { useMkForce = true; }
    // {
      PrivateDevices = lib.mkForce false;
    };
  };
}
