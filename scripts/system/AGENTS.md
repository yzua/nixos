# System Report Scripts

System health report generator and collector modules used by `system-report`.
This subtree is report-focused: collect metrics, format sections, and test collector behavior.

---

## Structure

| File | Purpose |
|------|---------|
| `report/system-report.sh` | Main entrypoint (`errors`, `full`, `view`, `view-errors`) |
| `report/report-collectors.sh` | Compatibility shim sourcing collector modules |
| `report/report-collectors-core.sh` | Core collectors (systemd errors/timers, traffic, builds, AI logs) |
| `report/report-collectors-observability.sh` | Netdata/Loki/Scrutiny/resource collectors |
| `report/report-collectors-security.sh` | Security collectors (fail2ban, Lynis, OpenSnitch, unit hardening) |
| `report/report-helpers.sh` | Shared helpers (`section`, `safe_cmd`, table output, status labels) |
| `report/report-collectors-test.sh` | Focused tests for helpers/collectors |

---

## Conventions

- Keep `system-report.sh` thin: orchestration only, heavy logic in collectors/helpers.
- Add collectors to the appropriate module file, then source through `report-collectors.sh`.
- Use `safe_cmd` and feature gates to degrade gracefully when services are unavailable.
- Keep markdown output deterministic (table header helpers, stable section order).
- Maintain shell portability and `shellcheck` compliance.

---

## Where To Look

- New report section: add collector function in `report-collectors-*.sh`, then call from `generate_full_report`.
- Shared formatting/JSON summary behavior: `report-helpers.sh`.
- Collector behavior tests: `report-collectors-test.sh`.

---

## Anti-Patterns

- Putting collector business logic directly in `system-report.sh`.
- Calling external commands without `safe_cmd` wrappers.
- Adding collector files without sourcing them in `report-collectors.sh`.
- Introducing output formats that break existing markdown/json consumers.

---

## Validation

```bash
just lint
bash scripts/system/report/report-collectors-test.sh
```
