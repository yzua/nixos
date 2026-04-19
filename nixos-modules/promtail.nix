# Promtail log shipper for Loki.

{
  config,
  lib,
  constants,
  systemdHelpers,
  ...
}:

let
  inherit (systemdHelpers) mkServiceHardening;
  inherit (constants) localhost ports;
in
{
  options.mySystem.promtail = {
    enable = lib.mkEnableOption "Promtail log shipper";
  };

  config = lib.mkIf config.mySystem.promtail.enable {
    services.promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = ports.promtail;
          http_listen_address = localhost;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        clients = [
          {
            url = "http://${localhost}:${toString ports.loki}/loki/api/v1/push";
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
      services.promtail.serviceConfig = mkServiceHardening {
        protectHome = true;
        useMkForce = true;
        memoryMax = "128M";
        memoryHigh = "64M";
      };

      tmpfiles.rules = [
        "d /var/lib/promtail 0750 promtail promtail -"
      ];
    };
  };
}
