# System Report Collectors

Modular system health reporting tool. Collects metrics from systemd, observability APIs (Netdata, Loki, Scrutiny), security services (fail2ban, OpenSnitch, Lynis), Nix build logs, and AI agent logs. Outputs structured markdown reports and JSON summary.

Parent: `scripts/system/AGENTS.md`

---

## Files

| File                                 | Purpose                                                                                                           |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `system-report.sh`                   | CLI entry point: modes `full`, `errors`, `view`, `view-errors`                                                    |
| `report-collectors.sh`               | Compatibility shim: sources core/observability/security modules                                                   |
| `report-collectors-core.sh`          | Core: failed services, journal errors, timers, network, Nix build rate, AI agent errors                           |
| `report-collectors-observability.sh` | Observability: CPU/RAM/disk from Netdata API, Loki errors, Netdata alarms, SMART health                           |
| `report-collectors-security.sh`      | Security: fail2ban bans, Lynis score, OpenSnitch blocks, systemd-analyze exposure                                 |
| `report-helpers.sh`                  | Shared helpers: `section()`, `safe_cmd()`, `query_api()`, `query_loki()`, `generate_json_summary()`, service URLs |
| `report-collectors-test.sh`          | Unit tests with mocked `safe_cmd()`                                                                               |

---

## Conventions

- All collector and helper files are **sourced, not executed** — no `set -euo pipefail` (inherited from caller).
- **Sourcing chain**: `system-report.sh` → `report-helpers.sh` + `report-collectors.sh` → core + observability + security.
- **Feature flags**: Observability/security collectors gated by env vars (`HAS_NETDATA`, `HAS_LOKI`, `HAS_SCRUTINY`, `HAS_OPENSNITCH`, `HAS_FAIL2BAN`). `require_enabled_feature()` prints `[unavailable]` and returns 1 when disabled.
- **Safe execution**: `safe_cmd()` wraps commands with `timeout`. `query_api()` wraps `curl` with timeout.
- **JSON summary**: Collector functions set `_`-prefixed globals (`_CPU`, `_MEM`, `_DISK_ROOT`, etc.) which `generate_json_summary()` reads.
- **Overridable paths**: Source paths overridable via env vars for testing.

---

## Gotchas

- Does NOT source `../lib/logging.sh`. Uses its own output helpers (`section()`, `print_table_header()`, `status_label()`).
- `_`-prefixed globals are shared state between collectors and `generate_json_summary()` — new collectors contributing to JSON summary must set a new `_` variable and add it to `generate_json_summary()`.
- `report-collectors-core.sh` sources `../lib/error-patterns.sh` and `../lib/log-dirs.sh` via computed `${SCRIPT_DIR}` path — fragile if caller doesn't set it.
- Service endpoint URLs (`NETDATA_URL`, `LOKI_URL`, `SCRUTINY_URL`) in `report-helpers.sh` are the single source of truth.
- JSON summary thresholds: disk >= 90% critical, >= 80% warning; > 50 journal errors/24h warning; any SMART failure or failed service is critical.

---

## Dependencies

- `../lib/error-patterns.sh` (AI agent log scanning), `../lib/log-dirs.sh` (log discovery), `../lib/test-helpers.sh` (tests)
- Does NOT depend on `../lib/logging.sh` or `../lib/require.sh`
- External: `systemctl`, `journalctl`, `vnstat`, `jq`, `curl`, `timeout`, `bat`, `fail2ban-client`, `systemd-analyze`, `date`, `bc`
- Nix: `system-report.sh` wrapped via `writeShellApplication` in `nixos-modules/system-report/_config.nix`
