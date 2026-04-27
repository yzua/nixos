# Build localhost service URLs from constants.ports.
# Shared by monitoring modules (prometheus-grafana, glance, system-report, etc.)

{ constants }:

let
  inherit (constants) localhost ports;
  mkUrl = port: "http://${localhost}:${toString port}";
in
{
  inherit localhost ports mkUrl;

  netdata = mkUrl ports.netdata;
  loki = mkUrl ports.loki;
  grafana = mkUrl ports.grafana;
  prometheus = mkUrl ports.prometheus;
  alertmanager = mkUrl ports.alertmanager;
  scrutiny = mkUrl ports.scrutiny;
  glance = mkUrl ports.glance;
  i2pd-webconsole = mkUrl ports.i2pd-webconsole;
  syncthing = mkUrl ports.syncthing;
  activitywatch = mkUrl ports.activitywatch;
}
