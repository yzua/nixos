# Shared helpers for Prometheus and Grafana configuration.

{ constants }:

let
  inherit (constants) localhost ports;
  urls = import ../helpers/_service-urls.nix { inherit constants; };

  mkStaticConfig = targets: [ { inherit targets; } ];

  mkDatasource =
    {
      name,
      type,
      url,
      uid,
      isDefault ? false,
    }:
    {
      inherit
        name
        type
        url
        uid
        isDefault
        ;
      access = "proxy";
      editable = true;
      orgId = 1;
      jsonData = { };
    };

  netdataTarget = "${localhost}:${toString ports.netdata}";
  lokiTarget = "${localhost}:${toString ports.loki}";
  alertmanagerTarget = "${localhost}:${toString ports.alertmanager}";

  datasources = [
    (mkDatasource {
      name = "Prometheus";
      type = "prometheus";
      url = urls.prometheus;
      uid = "prometheus";
      isDefault = true;
    })
    (mkDatasource {
      name = "Loki";
      type = "loki";
      url = "http://${lokiTarget}";
      uid = "loki";
    })
  ];
in
{
  inherit
    mkStaticConfig
    netdataTarget
    lokiTarget
    alertmanagerTarget
    datasources
    ;
}
