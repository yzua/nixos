# Alertmanager → ntfy.sh push notification bridge.
# Wired into the observability stack: Prometheus alerts → Alertmanager → ntfy.sh.

{
  config,
  constants,
  lib,
  pkgs,
  pkgsStable,
  systemdHelpers,
  ...
}:

let
  inherit (constants) localhost;
  inherit (systemdHelpers) mkServiceHardening;

  ntfyPort = config.mySystem.ntfy.port;

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
  config = lib.mkIf (config.mySystem.observability.enable && config.mySystem.ntfy.enable) {
    # alertmanager-ntfy: translates Alertmanager webhook JSON → ntfy.sh publish API.
    # Alertmanager sends to http://127.0.0.1:8090/hook, bridge forwards to https://ntfy.sh/<topic>.
    # Topic is read from sops secret (ntfy_topic) at runtime for privacy.
    systemd.services.alertmanager-ntfy = {
      description = "Alertmanager to ntfy.sh notification bridge";
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.sops.secrets.ntfy_topic.path ];

      script = ''
        TOPIC=$(cat ${config.sops.secrets.ntfy_topic.path})
        CONFIG=$(mktemp)
        ${pkgs.gnused}/bin/sed "s/NTFY_TOPIC_PLACEHOLDER/$TOPIC/" ${configTemplate} > "$CONFIG"
        exec ${pkgs.alertmanager-ntfy}/bin/alertmanager-ntfy \
          --configs "$CONFIG" \
          --http-addr ${localhost}:${toString ntfyPort}
      '';

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectory = "alertmanager-ntfy";
      }
      // mkServiceHardening {
        protectHome = true;
        memoryMax = "64M";
      };
    };

    # ntfy CLI for manual testing: ntfy pub $(cat /run/secrets/ntfy_topic) "message"
    environment.systemPackages = [ pkgsStable.ntfy-sh ];
  };
}
