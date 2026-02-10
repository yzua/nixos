# Weekly Lynis security audit timer and service.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ lynis ];

  systemd = {
    timers.security-audit = {
      description = "Weekly security audit";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        Unit = "security-audit.service";
      };
    };

    services.security-audit = {
      description = "Run Lynis security audit";
      serviceConfig = {
        Type = "oneshot";
        # NOTE: PrivateNetwork omitted so Lynis can audit network config
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/tmp" ];
        ExecStart = pkgs.writeShellScript "security-audit.sh" ''
          #!${pkgs.bash}/bin/bash
          echo 'Running Lynis audit...'
          ${pkgs.lynis}/bin/lynis audit system --quiet
          echo 'Security audit completed!'
        '';
      };
    };
  };
}
