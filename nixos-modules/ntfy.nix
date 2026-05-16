# ntfy.sh push notification integration.
# The alertmanager-ntfy bridge service lives in prometheus-grafana/_ntfy-bridge.nix
# (requires both observability and ntfy toggles).

{
  constants,
  lib,
  ...
}:

{
  options.mySystem.ntfy = {
    enable = lib.mkEnableOption "ntfy.sh push notification integration";

    port = lib.mkOption {
      type = lib.types.port;
      default = constants.ports.ntfy-bridge;
      description = "Port for the alertmanager-ntfy bridge to listen on.";
    };
  };
}
