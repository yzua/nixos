# Shared systemd timer/service constructors for security modules.
{ lib }:

{
  mkOneshotService =
    {
      description,
      execStart,
      extraServiceConfig ? { },
    }:
    {
      inherit description;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = execStart;
      }
      // extraServiceConfig;
    };

  mkPersistentTimer =
    {
      description,
      onCalendar,
      unit ? null,
      randomizedDelaySec ? null,
      wantedBy ? [ "timers.target" ],
    }:
    {
      inherit description wantedBy;
      timerConfig = {
        OnCalendar = onCalendar;
        Persistent = true;
      }
      // lib.optionalAttrs (unit != null) { Unit = unit; }
      // lib.optionalAttrs (randomizedDelaySec != null) { RandomizedDelaySec = randomizedDelaySec; };
    };
}
