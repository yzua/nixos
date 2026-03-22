# Cleanup Timers

Automated retention and cleanup timers guarded by `mySystem.cleanup.enable`.
This directory uses a shared helper (`_lib.nix`) to keep timer definitions consistent.

---

## Structure

| File            | Purpose                                                                    |
| --------------- | -------------------------------------------------------------------------- |
| `default.nix`   | Option definition + imports (`downloads.nix`, `cache.nix`)                 |
| `_lib.nix`      | Helper library exposing `mkCleanupTimer`, `mkFindCleanupTimer`, `bash`, `find`, `home` |
| `downloads.nix` | Download/media/screenshot/clipboard retention timers + user dir activation |
| `cache.nix`     | Cache cleanup timers (pip, npm, bun, go, Playwright, Docker)               |

---

## Conventions

- Always gate timers with `lib.mkIf config.mySystem.cleanup.enable`.
- Use `mkCleanupTimer` from `_lib.nix` for all timers instead of raw duplicated unit definitions.
- Prefer idempotent shell commands with safe fallbacks (`|| true`) for missing dirs/tools.
- Keep retention windows explicit in each timer (`mtime`, `calendar`, `delay`).
- Docker cleanup must remain safety-gated (skip when containers are running; preserve volumes).

---

## Where To Look

- Add a new retention rule: `downloads.nix` or `cache.nix` (choose by domain)
- Add shared timer behavior: `_lib.nix`
- Enable/disable globally: host config via `mySystem.cleanup.enable`

---

## Anti-Patterns

- Defining ad-hoc systemd units directly in these files instead of `mkCleanupTimer`.
- Running destructive cleanup without runtime guards (especially Docker).
- Importing `_lib.nix` through `default.nix` (helper files stay manual imports).
- Hardcoding a username path outside `/home/${user}` conventions.

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
```
