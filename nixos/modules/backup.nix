# Automated restic backups with retention policy.
{
  config,
  lib,
  user,
  ...
}:

{
  options.mySystem.backup = {
    enable = lib.mkEnableOption "automated restic backups";

    repository = lib.mkOption {
      type = lib.types.str;
      default = "/var/backup/restic";
      example = "s3:s3.amazonaws.com/my-backup-bucket";
      description = "Restic backup repository path (local or remote).";
    };
  };

  config = lib.mkIf config.mySystem.backup.enable {
    sops.secrets.restic-password = {
      sopsFile = ../../secrets/secrets.yaml;
    };

    services.restic.backups.home = {
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      inherit (config.mySystem.backup) repository;

      user = "root";

      paths = [
        "/home/${user}/Projects"
        "/home/${user}/Documents"
        "/home/${user}/System"
        "/home/${user}/.gnupg"
        "/home/${user}/.ssh"
        "/home/${user}/.config/sops"
      ];

      exclude = [
        "node_modules"
        ".direnv"
        "target"
        ".cache"
        "__pycache__"
        "*.pyc"
        ".git/objects"
        "*.tmp"
        "*.log"
      ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };
}
