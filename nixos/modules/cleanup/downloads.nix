{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  cleanupLib = import ./lib.nix { inherit pkgs user; };
  inherit (cleanupLib) mkCleanupTimer;
  bash = "${pkgs.bash}/bin/bash";
  find = "${pkgs.findutils}/bin/find";
  home = "/home/${user}";
in
{
  config = lib.mkIf config.mySystem.cleanup.enable (
    lib.mkMerge [
      (mkCleanupTimer {
        name = "telegram-downloads";
        description = "Clean up old Telegram downloads";
        command = "${bash} -c \"${find} '${home}/Downloads/Telegram Desktop' -type f -mtime +14 -delete 2>/dev/null || true\"";
        postCommand = "${bash} -c \"${find} '${home}/Downloads/Telegram Desktop' -type d -empty -delete 2>/dev/null || true\"";
        calendar = "daily";
        delay = "1h";
      })

      (mkCleanupTimer {
        name = "downloads";
        description = "Clean up old general downloads";
        command = "${bash} -c '${find} ${home}/Downloads -type f -mtime +30 -delete 2>/dev/null || true'";
        postCommand = "${bash} -c '${find} ${home}/Downloads -type d -empty -delete 2>/dev/null || true'";
        calendar = "weekly";
        delay = "2h";
      })

      (mkCleanupTimer {
        name = "screenshots";
        description = "Clean up old screenshots";
        command = "${bash} -c '${find} ${home}/Screens -type f -mtime +14 -delete 2>/dev/null || true'";
        postCommand = "${bash} -c '${find} ${home}/Screens -type d -empty -delete 2>/dev/null || true'";
        calendar = "monthly";
        delay = "2h";
      })

      (mkCleanupTimer {
        name = "telegram-desktop";
        description = "Clean up Telegram Desktop cached media";
        command = "${bash} -c '${find} ${home}/.local/share/TelegramDesktop -type f -mtime +60 -delete 2>/dev/null || true'";
        postCommand = "${bash} -c '${find} ${home}/.local/share/TelegramDesktop -type d -empty -delete 2>/dev/null || true'";
        calendar = "monthly";
        delay = "3h";
      })

      (mkCleanupTimer {
        name = "clipboard-history";
        description = "Clean up clipboard history (OPSEC - prevents sensitive data persistence)";
        command = "${bash} -c 'if [ -d ${home}/.cache/cliphist ]; then ${pkgs.cliphist}/bin/cliphist wipe && rm -f ${home}/.cache/cliphist/db; fi'";
        calendar = "daily";
        delay = "6h";
      })

      {
        # Ensure user directories exist
        system.activationScripts.createUserDirs = {
          text = ''
            mkdir -p /home/${user}/Downloads/Telegram\ Desktop
            mkdir -p /home/${user}/Screens
            chown ${user}:users /home/${user}/Downloads/Telegram\ Desktop
            chown ${user}:users /home/${user}/Screens
          '';
          deps = [ ];
        };
      }
    ]
  );
}
