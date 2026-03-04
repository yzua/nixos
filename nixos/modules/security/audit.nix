# Weekly Lynis security audit timer and service.
{
  lib,
  pkgs,
  ...
}:

let
  helpers = import ./_systemd-timer-helpers.nix { inherit lib; };
  inherit (helpers) mkOneshotService mkPersistentTimer;

  auditScript = pkgs.writeShellScript "security-audit.sh" ''
    #!${pkgs.bash}/bin/bash
    echo 'Running Lynis audit...'
    ${pkgs.lynis}/bin/lynis audit system --quiet
    echo 'Security audit completed!'
  '';
in

{
  environment.systemPackages = with pkgs; [ lynis ];

  systemd = {
    timers.security-audit = mkPersistentTimer {
      description = "Weekly security audit";
      onCalendar = "weekly";
      unit = "security-audit.service";
    };

    services.security-audit = mkOneshotService {
      description = "Run Lynis security audit";
      execStart = auditScript;
      extraServiceConfig = {
        # NOTE: PrivateNetwork omitted so Lynis can audit network config
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/tmp" ];
      };
    };
  };
}
