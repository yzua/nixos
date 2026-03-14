{ lib, ... }:
{
  mkOneshotHardening =
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
    }
    // lib.optionalAttrs (protectSystem != null) { ProtectSystem = wrap protectSystem; }
    // lib.optionalAttrs (memoryMax != null) { MemoryMax = memoryMax; }
    // lib.optionalAttrs (memoryHigh != null) { MemoryHigh = memoryHigh; };
}
