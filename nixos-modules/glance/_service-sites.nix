# Glance dashboard service health check endpoints

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
    url = "http://localhost:8082";
    icon = "mdi:view-dashboard-outline";
  }
  {
    title = "Netdata";
    url = "http://localhost:19999";
    icon = "si:netdata";
  }
  {
    title = "Grafana";
    url = "http://localhost:3001";
    icon = "si:grafana";
  }
  {
    title = "Prometheus";
    url = "http://localhost:9090";
    icon = "si:prometheus";
  }
  {
    title = "Alertmanager";
    url = "http://localhost:9093";
    icon = "mdi:alert-outline";
  }
  {
    title = "Scrutiny";
    url = "http://localhost:8080";
    icon = "mdi:harddisk";
  }
  {
    title = "I2PD Webconsole";
    url = "http://localhost:7070";
    icon = "mdi:router-network";
  }
  {
    title = "Syncthing";
    url = "http://localhost:8384";
    icon = "si:syncthing";
  }
  {
    title = "ActivityWatch";
    url = "http://localhost:5600";
    icon = "mdi:clock-check-outline";
  }
]
