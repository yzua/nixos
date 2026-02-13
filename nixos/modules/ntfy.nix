# Alertmanager → ntfy.sh push notification bridge (localhost:8090).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySystem.ntfy;

  # Config template for alertmanager-ntfy bridge.
  # Topic placeholder is replaced at runtime from sops secret.
  configTemplate = pkgs.writeText "alertmanager-ntfy-config.yml" ''
    ntfy:
      baseurl: https://ntfy.sh
      notification:
        topic: NTFY_TOPIC_PLACEHOLDER
        priority: |
          status == "firing" ? "urgent" : "default"
        tags:
          - tag: "+1"
            condition: status == "resolved"
          - tag: rotating_light
            condition: status == "firing"
        templates:
          title: |
            {{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}
          description: |
            {{ index .Annotations "description" }}
      async: false
  '';
in
{
  options.mySystem.ntfy = {
    enable = lib.mkEnableOption "Alertmanager to ntfy.sh push notification bridge";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port for the alertmanager-ntfy bridge to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    # alertmanager-ntfy: translates Alertmanager webhook JSON → ntfy.sh publish API.
    # Alertmanager sends to http://127.0.0.1:8090/hook, bridge forwards to https://ntfy.sh/<topic>.
    # Topic is read from sops secret (ntfy_topic) at runtime for privacy.
    systemd.services.alertmanager-ntfy = lib.mkIf config.mySystem.observability.enable {
      description = "Alertmanager to ntfy.sh notification bridge";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.sops.secrets.ntfy_topic.path ];

      script = ''
        TOPIC=$(cat ${config.sops.secrets.ntfy_topic.path})
        CONFIG=$(mktemp)
        ${pkgs.gnused}/bin/sed "s/NTFY_TOPIC_PLACEHOLDER/$TOPIC/" ${configTemplate} > "$CONFIG"
        exec ${pkgs.alertmanager-ntfy}/bin/alertmanager-ntfy \
          --configs "$CONFIG" \
          --http-addr 127.0.0.1:${toString cfg.port}
      '';

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectory = "alertmanager-ntfy";

        # Hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        MemoryMax = "64M";
      };
    };

    # ntfy CLI for manual testing: ntfy pub $(cat /run/secrets/ntfy_topic) "message"
    environment.systemPackages = [ pkgs.ntfy-sh ];
  };
}
