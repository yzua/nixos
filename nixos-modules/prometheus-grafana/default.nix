# Prometheus + Alertmanager + Grafana observability stack.

{ lib, ... }:

{
  imports = [
    ./_prometheus.nix # modules-check: manual-helper Prometheus + Alertmanager collection and alert routing
    ./_grafana.nix # modules-check: manual-helper Grafana dashboards and visualization
  ];

  options.mySystem.observability = {
    enable = lib.mkEnableOption "Prometheus + Grafana observability stack";
  };
}
