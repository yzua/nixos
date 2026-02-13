# Sets hostname and stateVersion from flake arguments.
{
  config,
  lib,
  hostname,
  stateVersion,
  ...
}:

{
  options.mySystem.hostInfo.enable = lib.mkEnableOption "automatic hostname and state version configuration";

  config = lib.mkIf config.mySystem.hostInfo.enable {
    networking.hostName = hostname;
    system.stateVersion = stateVersion;
  };
}
