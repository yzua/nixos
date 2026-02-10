# System monitoring (sensors, vnStat, bandwhich).
{ pkgsStable, ... }:

{
  environment.systemPackages = with pkgsStable; [
    iotop
    sysstat
    lm_sensors
  ];

  services.vnstat.enable = true;
  programs.bandwhich.enable = true;
}
