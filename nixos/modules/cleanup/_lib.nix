# Helper library for creating cleanup timers.
{ pkgs, user }:
{
  mkFindCleanupTimer =
    {
      name,
      description,
      path,
      mtimeDays,
      calendar,
      delay,
      serviceUser ? user,
      removeEmptyDirs ? true,
    }:
    let
      bash = "${pkgs.bash}/bin/bash";
      find = "${pkgs.findutils}/bin/find";
    in
    {
      systemd.services."cleanup-${name}" = {
        inherit description;
        serviceConfig = {
          Type = "oneshot";
          User = serviceUser;
          ExecStart = "${bash} -c \"${find} '${path}' -type f -mtime +${toString mtimeDays} -delete 2>/dev/null || true\"";
        }
        // pkgs.lib.optionalAttrs removeEmptyDirs {
          ExecStartPost = "${bash} -c \"${find} '${path}' -type d -empty -delete 2>/dev/null || true\"";
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
        // pkgs.lib.optionalAttrs (postCommand != null) {
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
}
