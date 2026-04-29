# Build localhost service URLs from constants.ports.
# Shared by monitoring modules (prometheus-grafana, glance, system-report, etc.)
# All URLs are auto-generated — add a port to constants.ports and it gets a URL.

{ constants }:

let
  inherit (constants) localhost ports;
  mkUrl = port: "http://${localhost}:${toString port}";
  urls = builtins.mapAttrs (_name: mkUrl) ports;
in
{
  inherit
    localhost
    ports
    mkUrl
    urls
    ;
}
