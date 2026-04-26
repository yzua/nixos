# Prometheus + Grafana Stack

Observability stack module for Prometheus, Alertmanager, and Grafana on localhost.
Enabled through `mySystem.observability.enable` and integrated with Netdata/Loki and ntfy bridge alerts.

---

## Structure

| File              | Purpose                                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| `default.nix`     | Main stack wiring: Prometheus scrape/jobs, Alertmanager route, Grafana provisioning, resource limits |
| `_prometheus.nix` | Prometheus and Alertmanager configuration (scrape targets, alert routing)                            |
| `_grafana.nix`    | Grafana server settings, provisioning, and datasource wiring                                         |
| `_helpers.nix`    | Shared helper functions (not a module, imported by other files)                                      |
| `alert-rules.nix` | Alert rule groups (system, disk, services, network)                                                  |
| `dashboards/`     | Provisioned Grafana dashboard JSON files                                                             |

---

## Conventions

- Keep services bound to loopback (`127.0.0.1`) unless explicitly changing security posture.
- Maintain dashboard provisioning via `pkgs.runCommand` copy workflow in `default.nix`.
- Keep alert routing centralized in Alertmanager config (currently webhook to ntfy bridge).
- Update alert thresholds in `alert-rules.nix`; keep labels and severity explicit.
- Keep memory limits for Prometheus/Alertmanager/Grafana aligned with module defaults.

---

## Dependencies

- `mySystem.observability.enable = true` toggles this stack.
- Expects Loki (`127.0.0.1:3100`) and Netdata (`127.0.0.1:19999`) scrape targets when enabled.
- Grafana admin password is sourced from sops secret path.

---

## Anti-Patterns

- Exposing Prometheus/Grafana/Alertmanager on non-localhost without explicit network hardening.
- Editing dashboard JSON inline in `default.nix` instead of `dashboards/*.json`.
- Duplicating alert rules in multiple files; keep them consolidated in `alert-rules.nix`.
- Hardcoding plaintext credentials in Grafana settings.

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
```
