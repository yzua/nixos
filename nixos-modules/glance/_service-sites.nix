# Glance dashboard service health check endpoints.
# Port numbers are injected from constants.ports to avoid drift.

{ constants }:

let
  urls = import ../helpers/_service-urls.nix { inherit constants; };
in
[
  {
    title = "Glance";
    url = urls.glance;
    icon = "mdi:view-dashboard-outline";
  }
  {
    title = "Netdata";
    url = urls.netdata;
    icon = "si:netdata";
  }
  {
    title = "Grafana";
    url = urls.grafana;
    icon = "si:grafana";
  }
  {
    title = "Prometheus";
    url = urls.prometheus;
    icon = "si:prometheus";
  }
  {
    title = "Alertmanager";
    url = urls.alertmanager;
    icon = "mdi:alert-outline";
  }
  {
    title = "Scrutiny";
    url = urls.scrutiny;
    icon = "mdi:harddisk";
  }
  {
    title = "I2PD Webconsole";
    url = urls.i2pd-webconsole;
    icon = "mdi:router-network";
  }
  {
    title = "Syncthing";
    url = urls.syncthing;
    icon = "si:syncthing";
  }
  {
    title = "ActivityWatch";
    url = urls.activitywatch;
    icon = "mdi:clock-check-outline";
  }
]
