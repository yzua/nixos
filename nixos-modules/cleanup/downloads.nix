# Download and media cleanup timers.

{
  config,
  lib,
  pkgs,
  systemdHelpers,
  user,
  ...
}:

let
  cleanupLib = import ./_lib.nix {
    inherit
      pkgs
      lib
      systemdHelpers
      user
      ;
  };
  inherit (cleanupLib)
    mkCleanupTimer
    mkFindCleanupTimer
    bash
    home
    ;
in
{
  config = lib.mkIf config.mySystem.cleanup.enable (
    lib.mkMerge [
      (mkFindCleanupTimer {
        name = "telegram-downloads";
        description = "Clean up old Telegram downloads";
        path = "${home}/Downloads/Telegram Desktop";
        mtimeDays = 14;
        calendar = "daily";
        delay = "1h";
      })

      (mkFindCleanupTimer {
        name = "downloads";
        description = "Clean up old general downloads";
        path = "${home}/Downloads";
        mtimeDays = 30;
        calendar = "weekly";
        delay = "2h";
      })

      (mkFindCleanupTimer {
        name = "screenshots";
        description = "Clean up old screenshots";
        path = "${home}/Screens";
        mtimeDays = 14;
        calendar = "monthly";
        delay = "2h";
      })

      (mkFindCleanupTimer {
        name = "telegram-desktop";
        description = "Clean up Telegram Desktop cached media";
        path = "${home}/.local/share/TelegramDesktop";
        mtimeDays = 60;
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
