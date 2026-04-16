# Glance dashboard service health check endpoints.
# Port numbers are injected from constants.ports to avoid drift.

{ ports }:

let
  mkSite =
    {
      title,
      url,
      icon,
    }:
    {
      inherit title url icon;
    };
in
map mkSite [
  {
    title = "Glance";
    url = "http://localhost:${toString ports.glance}";
    icon = "mdi:view-dashboard-outline";
  }
  {
    title = "Netdata";
    url = "http://localhost:${toString ports.netdata}";
    icon = "si:netdata";
  }
  {
    title = "Grafana";
    url = "http://localhost:${toString ports.grafana}";
    icon = "si:grafana";
  }
  {
    title = "Prometheus";
    url = "http://localhost:${toString ports.prometheus}";
    icon = "si:prometheus";
  }
  {
    title = "Alertmanager";
    url = "http://localhost:${toString ports.alertmanager}";
    icon = "mdi:alert-outline";
  }
  {
    title = "Scrutiny";
    url = "http://localhost:${toString ports.scrutiny}";
    icon = "mdi:harddisk";
  }
  {
    title = "I2PD Webconsole";
    url = "http://localhost:${toString ports.i2pd-webconsole}";
    icon = "mdi:router-network";
  }
  {
    title = "Syncthing";
    url = "http://localhost:${toString ports.syncthing}";
    icon = "si:syncthing";
  }
  {
    title = "ActivityWatch";
    url = "http://localhost:${toString ports.activitywatch}";
    icon = "mdi:clock-check-outline";
  }
]
