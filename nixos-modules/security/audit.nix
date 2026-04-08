# Weekly Lynis security audit timer and service.

{
  lib,
  pkgsStable,
  ...
}:

let
  helpers = import ./_systemd-timer-helpers.nix { inherit lib; };
  inherit (helpers) mkOneshotService mkPersistentTimer;

  auditScript = pkgsStable.writeShellScript "security-audit.sh" ''
    #!${pkgsStable.bash}/bin/bash
    echo 'Running Lynis audit...'
    ${pkgsStable.lynis}/bin/lynis audit system --quiet
    echo 'Security audit completed!'
  '';
in

{
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
