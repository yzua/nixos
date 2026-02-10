# Prometheus + Alertmanager + Grafana observability stack (localhost:9090, localhost:9093, localhost:3001).
{
  config,
  lib,
  pkgs,
  ...
}:

let
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
        listenAddress = "127.0.0.1";

        globalConfig = {
          scrape_interval = "30s"; # 30s sufficient for personal machine (halves disk/CPU vs 15s default)
          evaluation_interval = "30s";
        };

        scrapeConfigs = [
          {
            job_name = "netdata";
            metrics_path = "/api/v1/allmetrics";
            params.format = [ "prometheus" ];
            static_configs = [
              { targets = [ "127.0.0.1:19999" ]; }
            ];
          }
          {
            job_name = "loki";
            static_configs = [
              { targets = [ "127.0.0.1:3100" ]; }
            ];
          }
        ];

        rules = import ./alert-rules.nix;

        alertmanagers = [
          {
            static_configs = [
              { targets = [ "127.0.0.1:9093" ]; }
            ];
          }
        ];

        extraFlags = [
          "--storage.tsdb.retention.time=30d"
          "--storage.tsdb.retention.size=10GB"
        ];

        alertmanager = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9093;

          # Route all alerts to local log receiver (no external notification channel configured yet)
          # TODO: Add ntfy or Gotify webhook when notification service is set up
          configuration = {
            route = {
              receiver = "local-log";
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
                name = "local-log";
                webhook_configs = [
                  {
                    url = "http://127.0.0.1:9099/alertmanager"; # Placeholder — alerts logged to journal via alertmanager
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
            http_addr = "127.0.0.1";
            http_port = 3001;
          };

          security = {
            admin_user = "admin";
            admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
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
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:9090";
                uid = "prometheus";
                isDefault = true;
                editable = true;
                orgId = 1;
                jsonData = { };
              }
              {
                name = "Loki";
                type = "loki";
                access = "proxy";
                url = "http://127.0.0.1:3100";
                uid = "loki";
                editable = true;
                orgId = 1;
                jsonData = { };
              }
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
      prometheus.serviceConfig = {
        MemoryMax = "512M";
        MemoryHigh = "384M";
      };
      alertmanager.serviceConfig = {
        MemoryMax = "128M";
        MemoryHigh = "64M";
      };
      grafana.serviceConfig = {
        MemoryMax = "256M";
        MemoryHigh = "192M";
      };
    };
  };
}
