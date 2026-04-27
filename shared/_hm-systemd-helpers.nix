{ lib }:
rec {
  mkPersistentTimer =
    {
      description,
      onCalendar ? "weekly",
      randomizedDelaySec ? null,
      unit ? null,
    }:
    {
      Unit.Description = description;
      Timer = {
        OnCalendar = onCalendar;
        Persistent = true;
      }
      // lib.optionalAttrs (randomizedDelaySec != null) { inherit randomizedDelaySec; }
      // lib.optionalAttrs (unit != null) { Unit = unit; };
      Install.WantedBy = [ "timers.target" ];
    };

  mkWeeklyTimer = args: mkPersistentTimer (args // { onCalendar = args.onCalendar or "weekly"; });
}
