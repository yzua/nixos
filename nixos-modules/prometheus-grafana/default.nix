# Prometheus + Alertmanager + Grafana observability stack.

{
  config,
  lib,
  pkgs,
  constants,
  systemdHelpers,
  ...
}:

let
  inherit (systemdHelpers) mkServiceHardening;

  inherit (constants) localhost ports;
  netdataTarget = "${localhost}:${toString ports.netdata}";
  lokiTarget = "${localhost}:${toString ports.loki}";
  prometheusTarget = "${localhost}:${toString ports.prometheus}";
  alertmanagerTarget = "${localhost}:${toString ports.alertmanager}";
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
  datasources = [
    (mkDatasource {
      name = "Prometheus";
      type = "prometheus";
      url = "http://${prometheusTarget}";
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
  dashboardDir = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${./dashboards/system-overview.json} $out/system-overview.json
    cp ${./dashboards/log-errors.json} $out/log-errors.json
  '';
in
{
  options.mySystem.observability = {
    enable = lib.mkEnableOption "Prometheus + Grafana observability stack";
  };

  config = lib.mkIf config.mySystem.observability.enable {
    services = {
      # === Prometheus + Alertmanager ===
      prometheus = {
        enable = true;
        port = ports.prometheus;
        listenAddress = localhost;

        globalConfig = {
          scrape_interval = "30s"; # 30s sufficient for personal machine (halves disk/CPU vs 15s default)
          evaluation_interval = "30s";
        };

        scrapeConfigs = [
          {
            job_name = "netdata";
            metrics_path = "/api/v1/allmetrics";
            params.format = [ "prometheus" ];
            static_configs = mkStaticConfig [ netdataTarget ];
          }
          {
            job_name = "loki";
            static_configs = mkStaticConfig [ lokiTarget ];
          }
        ];

        rules = import ./alert-rules.nix;

        alertmanagers = [
          {
            static_configs = mkStaticConfig [ alertmanagerTarget ];
          }
        ];

        extraFlags = [
          "--storage.tsdb.retention.time=30d"
          "--storage.tsdb.retention.size=10GB"
        ];

        alertmanager = {
          enable = true;
          listenAddress = localhost;
          port = ports.alertmanager;
          extraFlags = [
            "--cluster.listen-address="
          ];

          # Route all alerts via alertmanager-ntfy bridge → ntfy.sh
          configuration = {
            route = {
              receiver = "ntfy";
              group_by = [
                "alertname"
                "severity"
              ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            };
            receivers = [
              {
                name = "ntfy";
                webhook_configs = [
                  {
                    url = "http://${localhost}:${toString config.mySystem.ntfy.port}/hook";
                    send_resolved = true;
                  }
                ];
              }
            ];
          };
        };
      };

      # === Grafana ===
      grafana = {
        enable = true;

        settings = {
          server = {
            http_addr = localhost;
            http_port = ports.grafana;
          };

          security = {
            admin_user = "admin";
            admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
            secret_key = "$__file{${config.sops.secrets.grafana_admin_password.path}}"; # TODO: use a dedicated grafana_secret_key sops secret — reusing admin_password means rotating it breaks encrypted datasources
          };

          "auth.anonymous".enabled = false;
          analytics.reporting_enabled = false;
        };

        provision = {
          datasources.settings = {
            apiVersion = 1;
            deleteDatasources = map (ds: { inherit (ds) name orgId; }) datasources;
            inherit datasources;
          };

          dashboards.settings.providers = [
            {
              name = "default";
              options.path = dashboardDir;
            }
          ];
        };
      };
    };

    # === Resource Limits ===
    systemd.services = {
      prometheus.serviceConfig = mkServiceHardening {
        memoryMax = "512M";
        memoryHigh = "384M";
        protectHome = lib.mkDefault "read-only";
        protectSystem = lib.mkDefault "strict";
      };
      alertmanager.serviceConfig = mkServiceHardening {
        memoryMax = "128M";
        memoryHigh = "64M";
        protectHome = lib.mkDefault "read-only";
      };
      grafana = {
        restartTriggers = [ config.sops.secrets.grafana_admin_password.path ];
        serviceConfig = mkServiceHardening {
          memoryMax = "256M";
          memoryHigh = "192M";
          protectHome = lib.mkDefault "read-only";
          protectSystem = lib.mkDefault "strict";
        };
      };
    };
  };
}
