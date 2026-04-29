# Noctalia Shell IPC helper.
# Wraps `noctalia-shell ipc call` with start-then-retry logic:
# if Noctalia is not running, starts it and retries after a brief delay.

{
  config,
  pkgs,
  lib,
}:

cmd:
[
  "${pkgs.bash}/bin/sh"
  "-c"
  "if ! ${config.home.profileDirectory}/bin/noctalia-shell ipc call \"$@\" >/dev/null 2>&1; then ${pkgs.coreutils}/bin/nohup ${config.home.profileDirectory}/bin/noctalia-shell >/dev/null 2>&1 & ${pkgs.coreutils}/bin/sleep 0.35; ${config.home.profileDirectory}/bin/noctalia-shell ipc call \"$@\" >/dev/null 2>&1 || true; fi"
  "sh"
]
++ (lib.splitString " " cmd)
