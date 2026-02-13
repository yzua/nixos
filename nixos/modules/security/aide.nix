# Weekly AIDE file integrity monitoring.
{
  pkgs,
  user,
  ...
}:

let
  aideConf = pkgs.writeText "aide.conf" ''
    database_in=file:/var/lib/aide/aide.db
    database_out=file:/var/lib/aide/aide.db.new
    database_new=file:/var/lib/aide/aide.db.new

    # Rule definitions
    NORMAL = p+i+n+u+g+s+m+c+sha256
    DIR = p+i+n+u+g
    LOG = p+u+g+i+n+S

    # Critical system paths
    /etc NORMAL
    /boot NORMAL

    # User-sensitive files
    /home/${user}/.gnupg NORMAL
    /home/${user}/.ssh NORMAL
    /home/${user}/.config/sops NORMAL

    # Skip noisy directories
    !/etc/adjtime
    !/etc/resolv.conf
    !/etc/mtab
    !/var
    !/nix
    !/proc
    !/sys
    !/dev
    !/run
    !/tmp
  '';
in
{
  environment.systemPackages = [ pkgs.aide ];

  systemd = {
    timers.aide-check = {
      description = "Weekly AIDE file integrity check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "2h";
        Unit = "aide-check.service";
      };
    };

    services.aide-check = {
      description = "Run AIDE file integrity check";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "aide-check.sh" ''
          set -euo pipefail
          AIDE_DB="/var/lib/aide"
          mkdir -p "$AIDE_DB"

          if [[ ! -f "$AIDE_DB/aide.db" ]]; then
            echo "Initializing AIDE database..."
            ${pkgs.aide}/bin/aide --config=${aideConf} --init
            mv "$AIDE_DB/aide.db.new" "$AIDE_DB/aide.db"
            echo "AIDE database initialized"
          else
            echo "Running AIDE integrity check..."
            ${pkgs.aide}/bin/aide --config=${aideConf} --check || true
            echo "AIDE check completed"
          fi
        '';
      };
    };
  };
}
