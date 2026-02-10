# Loki log aggregation with Promtail (localhost:3100).
{
  config,
  lib,
  ...
}:

{
  options.mySystem.loki = {
    enable = lib.mkEnableOption "Loki log aggregation";
  };

  config = lib.mkIf config.mySystem.loki.enable {
    services.loki = {
      enable = true;

      configuration = {
        auth_enabled = false; # Single-tenant, localhost only

        server = {
          http_listen_port = 3100;
          http_listen_address = "127.0.0.1";
          grpc_listen_port = 9096;
          grpc_listen_address = "127.0.0.1";
        };

        common = {
          path_prefix = "/var/lib/loki";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
          replication_factor = 1;
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          instance_interface_names = [ ]; # Skip interface detection (fails on NixOS)
          instance_addr = "127.0.0.1";
        };

        schema_config = {
          configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        limits_config = {
          retention_period = "720h"; # 30 days
          ingestion_rate_mb = 4;
          ingestion_burst_size_mb = 6;
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          retention_delete_delay = "2h";
          delete_request_store = "filesystem";
        };
      };
    };

    services.promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = 9080;
          http_listen_address = "127.0.0.1";
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        clients = [
          {
            url = "http://127.0.0.1:3100/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__hostname" ];
                target_label = "hostname";
              }
              {
                source_labels = [ "__journal_priority_keyword" ];
                target_label = "level";
              }
            ];
          }
        ];
      };
    };

    users.users.promtail.extraGroups = [ "systemd-journal" ];

    # SECURITY: Systemd hardening directives + resource limits
    systemd = {
      services = {
        loki.serviceConfig = {
          MemoryMax = "256M";
          MemoryHigh = "192M";
          PrivateTmp = lib.mkForce true;
          ProtectSystem = lib.mkForce "strict"; # Upstream sets "full"; we want stricter
          ProtectHome = lib.mkForce true;
          NoNewPrivileges = lib.mkForce true;
          ProtectKernelTunables = lib.mkForce true;
          ProtectControlGroups = lib.mkForce true;
          RestrictSUIDSGID = lib.mkForce true;
          ReadWritePaths = [ "/var/lib/loki" ];
        };

        promtail.serviceConfig = {
          MemoryMax = "128M";
          MemoryHigh = "64M";
          PrivateTmp = lib.mkForce true;
          ProtectSystem = lib.mkForce "strict";
          ProtectHome = lib.mkForce true;
          NoNewPrivileges = lib.mkForce true;
          ProtectKernelTunables = lib.mkForce true;
          ProtectControlGroups = lib.mkForce true;
          RestrictSUIDSGID = lib.mkForce true;
          ReadWritePaths = [ "/var/lib/promtail" ];
        };
      };

      tmpfiles.rules = [
        "d /var/lib/promtail 0750 promtail promtail -"
      ];
    };
  };
}
