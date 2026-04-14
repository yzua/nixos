# System monitoring (sensors, vnStat, bandwhich).

{
  config,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.monitoring = {
    enable = lib.mkEnableOption "system monitoring tools (iotop, sysstat, sensors, vnStat, bandwhich)";
  };

  config = lib.mkIf config.mySystem.monitoring.enable {
    environment.systemPackages = with pkgsStable; [
      iotop
      sysstat
      lm_sensors
      smartmontools # SMART disk health (used by Netdata, Scrutiny)
    ];

    services.vnstat.enable = true;
    programs.bandwhich.enable = true;
  };
}
