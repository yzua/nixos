# Reusable systemd service hardening helper for oneshot/monitoring services.
{ lib, ... }:
{
  # Standard hardening for oneshot/monitoring services.
  # - readWritePaths: List of paths the service needs write access to
  # - protectHome: "read-only" (default) or true (stricter)
  # - memoryMax: Optional memory limit (e.g., "256M")
  # - memoryHigh: Optional high memory threshold (e.g., "192M")
  # - useMkForce: Whether to wrap values in lib.mkForce (for overriding upstream)
  mkOneshotHardening =
    {
      readWritePaths,
      protectHome ? "read-only",
      memoryMax ? null,
      memoryHigh ? null,
      useMkForce ? false,
    }:
    let
      wrap = if useMkForce then lib.mkForce else (x: x);
    in
    {
      inherit readWritePaths;
      PrivateTmp = wrap true;
      ProtectSystem = wrap "strict";
      ProtectHome = wrap protectHome;
      NoNewPrivileges = wrap true;
      ProtectKernelTunables = wrap true;
      ProtectControlGroups = wrap true;
      RestrictSUIDSGID = wrap true;
    }
    // lib.optionalAttrs (memoryMax != null) { MemoryMax = memoryMax; }
    // lib.optionalAttrs (memoryHigh != null) { MemoryHigh = memoryHigh; };
}
