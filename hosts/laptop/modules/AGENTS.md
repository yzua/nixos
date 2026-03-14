# Laptop Host Modules

ThinkPad-specific hardware modules layered on top of shared `nixos/modules` defaults.
Use this directory only for laptop-only behavior (power, thermals, Optimus, kernel params).

---

## Structure

| File          | Purpose                                                                             |
| ------------- | ----------------------------------------------------------------------------------- |
| `default.nix` | Import hub for all laptop-only modules                                              |
| `boot.nix`    | Kernel params (`acpi_backlight=native`, `nvidia_drm.fbdev=1`)                       |
| `nvidia.nix`  | NVIDIA Optimus offload + `mySystem.nvidia.{intelBusId,nvidiaBusId}` options         |
| `power.nix`   | Enables power mgmt, disables `power-profiles-daemon`, loads ThinkPad kernel modules |
| `tlp.nix`     | TLP policy + battery charge thresholds via `mySystem.laptop.battery.*`              |
| `thermal.nix` | Enables `services.thermald`                                                         |

---

## Conventions

- Keep laptop-only options in this subtree (`mySystem.laptop.*`, laptop `mySystem.nvidia.*` bus IDs).
- Preserve TLP as the active power daemon and keep `power-profiles-daemon` disabled here.
- Keep battery thresholds configurable through options, not hardcoded values in host config.
- Keep boot params limited to hardware bring-up needs for this model.

---

## Coordination Rules

- Cross-module conflicts are enforced in `nixos/modules/validation.nix` (power daemon conflicts, driver constraints).
- Shared defaults belong in `nixos/modules/host-defaults.nix`; this directory should only override laptop deltas.
- Host-level values are set in `hosts/laptop/configuration.nix` and consumed here.

---

## Anti-Patterns

- Moving shared behavior from `nixos/modules` into this host-specific subtree.
- Enabling both TLP and `power-profiles-daemon`.
- Hardcoding PCI bus IDs in unrelated files instead of `mySystem.nvidia.*` options.
- Editing `hardware-configuration.nix` to implement policy logic.

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
just nixos
```
