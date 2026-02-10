# greetd display manager with tuigreet TUI greeter.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
  };

  config = lib.mkIf config.mySystem.greetd.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
        user = "greeter";
      };
    };

    # Suppress duplicate login messages on tty1
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      # SECURITY: Systemd hardening directives (mkForce to override upstream defaults)
      PrivateTmp = lib.mkForce true;
      ProtectSystem = lib.mkForce "strict";
      ProtectKernelTunables = lib.mkForce true;
      NoNewPrivileges = lib.mkForce true;
    };
  };
}
