# Shared helpers for Prometheus and Grafana configuration.

{ constants }:

let
  inherit (constants) urls;

  # Strip http:// prefix for Prometheus scrape targets (needs host:port form)
  mkTarget = url: builtins.substring 7 (builtins.stringLength url - 7) url;

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

  netdataTarget = mkTarget urls.netdata;
  lokiTarget = mkTarget urls.loki;
  alertmanagerTarget = mkTarget urls.alertmanager;

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
