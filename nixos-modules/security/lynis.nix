# Weekly Lynis security audit timer and service.

{
  config,
  lib,
  pkgsStable,
  ...
}:

let
  inherit (import ../helpers/_systemd-helpers.nix { inherit lib; })
    mkServiceHardening
    mkOneshotService
    mkPersistentTimer
    ;

  auditScript = pkgsStable.writeShellScript "security-audit.sh" ''
    #!${pkgsStable.bash}/bin/bash
    echo 'Running Lynis audit...'
    ${pkgsStable.lynis}/bin/lynis audit system --quiet
    echo 'Security audit completed!'
  '';
in

{
  options.mySystem.lynis = {
    enable = lib.mkEnableOption "weekly Lynis security audit";
  };

  config = lib.mkIf config.mySystem.lynis.enable {
    environment.systemPackages = [ pkgsStable.lynis ];

    systemd = {
      timers.security-audit = mkPersistentTimer {
        description = "Weekly security audit";
        onCalendar = "weekly";
        unit = "security-audit.service";
      };

      services.security-audit = mkOneshotService {
        description = "Run Lynis security audit";
        execStart = auditScript;
        extraServiceConfig = mkServiceHardening {
          readWritePaths = [ "/tmp" ];
          # NOTE: PrivateNetwork omitted so Lynis can audit network config
        };
      };
    };
  };
}
