# Prometheus + Alertmanager + Grafana observability stack (localhost:9090, localhost:9093, localhost:3001).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  localhost = "127.0.0.1";
  netdataTarget = "${localhost}:19999";
  lokiTarget = "${localhost}:3100";
  prometheusTarget = "${localhost}:9090";
  alertmanagerTarget = "${localhost}:9093";
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
  mkMemoryService =
    {
      max,
      high,
    }:
    {
      MemoryMax = max;
      MemoryHigh = high;
    };
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
        port = 9090;
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
          port = 9093;
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
                    url = "http://127.0.0.1:${toString config.mySystem.ntfy.port}/hook";
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
            http_port = 3001;
          };

          database = {
            type = "sqlite3";
            wal = true;
            cache_mode = "private";
            transaction_retries = 10;
            query_retries = 5;
          };

          security = {
            admin_user = "admin";
            admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
            secret_key = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
          };

          "auth.anonymous".enabled = false;
          analytics.reporting_enabled = false;
        };

        provision = {
          datasources.settings = {
            apiVersion = 1;
            deleteDatasources = [
              {
                name = "Prometheus";
                orgId = 1;
              }
              {
                name = "Loki";
                orgId = 1;
              }
            ];
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
      prometheus.serviceConfig = mkMemoryService {
        max = "512M";
        high = "384M";
      };
      alertmanager.serviceConfig = mkMemoryService {
        max = "128M";
        high = "64M";
      };
      grafana = {
        restartTriggers = [ config.sops.secrets.grafana_admin_password.path ];
        serviceConfig = mkMemoryService {
          max = "256M";
          high = "192M";
        };
      };
    };
  };
}
