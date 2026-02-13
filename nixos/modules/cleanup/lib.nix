{ pkgs, user }:
{
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
