# Cache cleanup timers (PIP, Playwright, Bun, Go, npm, Docker).

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
    mkCachePurgeTimer
    mkFindCleanupTimer
    bash
    find
    home
    ;
in
{
  config = lib.mkIf config.mySystem.cleanup.enable (
    lib.mkMerge [
      (mkCleanupTimer {
        name = "cache";
        description = "Clean up user cache files";
        command = "${bash} -c '${pkgs.coreutils}/bin/du -sh ${home}/.cache 2>/dev/null || true'";
        postCommand = "${bash} -c 'if [ -d ${home}/.cache ]; then ${find} ${home}/.cache -type f -mtime +30 -delete 2>/dev/null || true; fi'";
        calendar = "weekly";
        delay = "3h";
      })

      (mkCachePurgeTimer {
        name = "pip-cache";
        description = "Clean up PIP package cache";
        binary = "pip";
        cacheCommand = "cache purge";
        calendar = "weekly";
      })

      (mkFindCleanupTimer {
        name = "playwright";
        description = "Clean up Playwright browser cache";
        path = "${home}/.cache/ms-playwright";
        mtimeDays = 30;
        calendar = "monthly";
        delay = "2h";
      })

      (mkCachePurgeTimer {
        name = "bun-cache";
        description = "Clean up Bun package manager cache";
        binary = "bun";
        cacheCommand = "pm cache rm";
      })

      (mkCachePurgeTimer {
        name = "go-cache";
        description = "Clean up Go modules cache";
        binary = "go";
        cacheCommand = "clean -modcache";
      })

      (mkCachePurgeTimer {
        name = "npm-cache";
        description = "Clean up npm cache";
        binary = "npm";
        cacheCommand = "cache clean --force";
      })

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
    ]
  );
}
