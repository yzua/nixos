# NixOS System Scope

Top-level system boundary for host wiring. This directory only contains `modules/`; host entrypoints live in `hosts/<hostname>/configuration.nix`.

---

## Structure

| Path                        | Role                                                   |
| --------------------------- | ------------------------------------------------------ |
| `modules/`                  | Shared NixOS modules imported by every host            |
| `modules/default.nix`       | System import hub (module aggregation order)           |
| `modules/host-defaults.nix` | Profile defaults (`desktop`/`laptop`) for `mySystem.*` |
| `modules/validation.nix`    | Cross-module assertions and forbidden combinations     |

---

## Where To Look

- Add/modify a system feature: `nixos/modules/<feature>.nix`
- Add cross-module conflict or dependency rule: `nixos/modules/validation.nix`
- Adjust profile-wide defaults: `nixos/modules/host-defaults.nix`
- Add submodule family (security/cleanup/observability): `nixos/modules/<dir>/default.nix`

---

## Conventions

- Keep shared system behavior in `nixos/modules/`; keep host-specific deltas in `hosts/<hostname>/modules/`.
- Feature options belong under `mySystem.*` and should be guarded with `lib.mkIf` when optional.
- Every module directory with `.nix` files must expose an import hub `default.nix` with inline purpose comments.
- `_*.nix` files are helpers and stay manually imported (not listed as normal module imports).
- Put hard safety checks in `validation.nix`, not scattered across unrelated modules.

---

## Anti-Patterns

- Adding host-specific hardware policy directly under `nixos/modules/`.
- Enabling conflicting services without a corresponding validation assertion.
- Duplicating `host-defaults.nix` logic inside host configs instead of overriding selectively.
- Treating helper files (`_*.nix`) as normal import-hub entries.

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
```
