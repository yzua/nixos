# Unified systemd helpers: service hardening, persistent timers, oneshot services.

{ lib, ... }:
{
  mkServiceHardening =
    {
      readWritePaths ? [ ],
      protectHome ? "read-only",
      protectSystem ? "strict",
      memoryMax ? null,
      memoryHigh ? null,
      useMkForce ? false,
    }:
    let
      wrap = if useMkForce then lib.mkForce else (x: x);
    in
    lib.optionalAttrs (readWritePaths != [ ]) { ReadWritePaths = readWritePaths; }
    // {
      PrivateTmp = wrap true;
      ProtectHome = wrap protectHome;
      NoNewPrivileges = wrap true;
      ProtectKernelTunables = wrap true;
      ProtectControlGroups = wrap true;
      RestrictSUIDSGID = wrap true;
      LockPersonality = wrap true;
      MemoryDenyWriteExecute = wrap true;
      RestrictNamespaces = wrap true;
      PrivateDevices = wrap true;
      ProtectClock = wrap true;
      ProtectHostname = wrap true;
      RemoveIPC = wrap true;
      SystemCallArchitectures = wrap "native";
    }
    // lib.optionalAttrs (protectSystem != null) { ProtectSystem = wrap protectSystem; }
    // lib.optionalAttrs (memoryMax != null) { MemoryMax = memoryMax; }
    // lib.optionalAttrs (memoryHigh != null) { MemoryHigh = memoryHigh; };

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

  mkOneshotService =
    {
      description,
      execStart,
      remainAfterExit ? true,
      extraServiceConfig ? { },
    }:
    {
      inherit description;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = remainAfterExit;
        ExecStart = execStart;
      }
      // extraServiceConfig;
    };
}
