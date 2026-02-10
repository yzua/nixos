# OpenSnitch application firewall with per-app network logging.
{
  config,
  lib,
  ...
}:

{
  options.mySystem.opensnitch = {
    enable = lib.mkEnableOption "OpenSnitch application firewall with per-app network logging";
  };

  config = lib.mkIf config.mySystem.opensnitch.enable {
    services.opensnitch = {
      enable = true;

      settings = {
        DefaultAction = "deny"; # Block all unknown outbound connections
        DefaultDuration = "always";
        ProcMonitorMethod = "ebpf";
        Firewall = "nftables";
        LogLevel = 1; # warning
      };
    };
  };
}
