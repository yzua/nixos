# Automated cleanup timers for downloads, caches, and containers.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  mkCleanupTimer =
    {
      name,
      description,
      command,
      postCommand ? null,
      calendar,
      delay,
      serviceUser ? user,
    }:
    {
      systemd.services."cleanup-${name}" = {
        inherit description;
        serviceConfig = {
          Type = "oneshot";
          User = serviceUser;
          ExecStart = command;
        }
        // lib.optionalAttrs (postCommand != null) {
          ExecStartPost = postCommand;
        };
      };
      systemd.timers."cleanup-${name}" = {
        description = "Timer for ${description}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = calendar;
          Persistent = true;
          RandomizedDelaySec = delay;
        };
      };
    };

  bash = "${pkgs.bash}/bin/bash";
  find = "${pkgs.findutils}/bin/find";
  home = "/home/${user}";
in
{
  options.mySystem.cleanup.enable = lib.mkEnableOption "automated file and cache cleanup services";

  config = lib.mkIf config.mySystem.cleanup.enable (
    lib.mkMerge [
      # === Downloads & Screenshots ===

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

      # === Caches ===

      (mkCleanupTimer {
        name = "cache";
        description = "Clean up user cache files";
        command = "${bash} -c '${pkgs.coreutils}/bin/du -sh ${home}/.cache 2>/dev/null || true'";
        postCommand = "${bash} -c 'if [ -d ${home}/.cache ]; then ${find} ${home}/.cache -type f -mtime +30 -delete 2>/dev/null || true; fi'";
        calendar = "weekly";
        delay = "3h";
      })

      (mkCleanupTimer {
        name = "pip-cache";
        description = "Clean up PIP package cache";
        command = "${bash} -c 'if command -v pip >/dev/null 2>&1; then pip cache purge 2>/dev/null || true; fi'";
        calendar = "weekly";
        delay = "1h";
      })

      (mkCleanupTimer {
        name = "playwright";
        description = "Clean up Playwright browser cache";
        command = "${bash} -c '${find} ${home}/.cache/ms-playwright -type d -mtime +30 -delete 2>/dev/null || true'";
        postCommand = "${bash} -c '${find} ${home}/.cache/ms-playwright -type d -empty -delete 2>/dev/null || true'";
        calendar = "monthly";
        delay = "2h";
      })

      (mkCleanupTimer {
        name = "bun-cache";
        description = "Clean up Bun package manager cache";
        command = "${bash} -c 'if command -v bun >/dev/null 2>&1; then bun pm cache rm 2>/dev/null || true; fi'";
        calendar = "monthly";
        delay = "1h";
      })

      (mkCleanupTimer {
        name = "go-cache";
        description = "Clean up Go modules cache";
        command = "${bash} -c 'if command -v go >/dev/null 2>&1; then go clean -modcache 2>/dev/null || true; fi'";
        calendar = "monthly";
        delay = "1h";
      })

      (mkCleanupTimer {
        name = "npm-cache";
        description = "Clean up npm cache";
        command = "${bash} -c 'if command -v npm >/dev/null 2>&1; then npm cache clean --force 2>/dev/null || true; fi'";
        calendar = "monthly";
        delay = "1h";
      })

      # === Docker ===

      (mkCleanupTimer {
        name = "docker";
        description = "Clean up Docker system (preserves volumes, only when no containers running)";
        command = pkgs.writeShellScript "safe-docker-cleanup" ''
          #!${pkgs.bash}/bin/bash
          # Safety check: only clean if Docker is running and no containers active
          if ! ${pkgs.docker}/bin/docker info &>/dev/null; then
            echo "Docker daemon not running, skipping cleanup"
            exit 0
          fi

          running=$(${pkgs.docker}/bin/docker ps -q 2>/dev/null | wc -l)
          if [ "$running" -eq 0 ]; then
            echo "No containers running, proceeding with cleanup..."
            # NOTE: --volumes removed to preserve persistent data
            ${pkgs.docker}/bin/docker system prune --all --force
            echo "Docker cleanup completed (volumes preserved)"
          else
            echo "Skipping cleanup: $running container(s) currently running"
          fi
        '';
        calendar = "monthly";
        delay = "2h";
        serviceUser = "root";
      })

      # === Telegram Desktop ===

      (mkCleanupTimer {
        name = "telegram-desktop";
        description = "Clean up Telegram Desktop cached media";
        command = "${bash} -c '${find} ${home}/.local/share/TelegramDesktop -type f -mtime +60 -delete 2>/dev/null || true'";
        postCommand = "${bash} -c '${find} ${home}/.local/share/TelegramDesktop -type d -empty -delete 2>/dev/null || true'";
        calendar = "monthly";
        delay = "3h";
      })

      # === PRIVACY: Clipboard History Cleanup ===

      (mkCleanupTimer {
        name = "clipboard-history";
        description = "Clean up clipboard history (OPSEC - prevents sensitive data persistence)";
        command = "${bash} -c 'if [ -d ${home}/.cache/cliphist ]; then ${pkgs.cliphist}/bin/cliphist wipe && rm -f ${home}/.cache/cliphist/db; fi'";
        calendar = "daily";
        delay = "6h";
      })

      # === Activation Scripts ===

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
