# Cache cleanup timers (PIP, Playwright, Bun, Go, npm, Docker).
{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  cleanupLib = import ./_lib.nix { inherit pkgs user; };
  inherit (cleanupLib) mkCleanupTimer;
  bash = "${pkgs.bash}/bin/bash";
  find = "${pkgs.findutils}/bin/find";
  home = "/home/${user}";
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
