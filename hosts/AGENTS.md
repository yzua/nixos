# Host Configurations

Active host: `desktop`. Dormant host: `laptop` (`enabled = false` in `hosts/_inventory.nix`, kept for future use).

Each host sets `mySystem.hostProfile` for profile-based defaults (via `host-defaults.nix`) and overrides specific options as needed.

---

## Host Comparison

| Setting | desktop | laptop (dormant) |
|---------|-------------|-------------------|
| Gaming | enabled + Gamescope | disabled |
| Bluetooth | disabled | enabled (manual start) |
| NVIDIA Optimus | — | Intel + NVIDIA hybrid |
| Power mgmt | minimal | TLP (charge limits 75-80%) |
| Avahi interface | `eno1` (ethernet) | `wlp0s20f3` (WiFi) |
| Sandboxing | enabled | enabled |
| Privacy stack | full (VPN, Tor, DNS, MAC) | full (VPN, Tor, DNS, MAC) |
| VNC remote access | enabled | — |
| KDE Connect | disabled (overridden in host config) | enabled |

---

## Directory Structure

```
hosts/<hostname>/
├── configuration.nix          # Main config: imports + mySystem.* options
├── hardware-configuration.nix # Auto-generated (NEVER edit)
├── local-packages.nix         # Host-specific packages
└── modules/
    ├── default.nix            # Host module aggregation
    └── *.nix                  # Hardware-specific modules
```

### PC modules
- `default.nix` applies small desktop-specific tuning (kernel params and BFQ scheduler udev rule)

### Laptop modules
- `boot.nix` — Kernel params (`acpi_backlight=native`, `nvidia_drm.fbdev=1`)
- `nvidia.nix` — Optimus offload mode (`mySystem.nvidia.*` bus IDs from laptop module options), fine-grained power mgmt
- `power.nix` — Disables power-profiles-daemon, loads laptop kernel modules (thinkpad_acpi, tp_smapi)
- `tlp.nix` — Battery thresholds (75-80%), CPU governor, WiFi power saving
- `thermal.nix` — thermald for Intel DPTF thermal zone management

---

## Host-Specific Options

Laptop defines extra options not used by desktop:
```nix
mySystem.nvidia.intelBusId    # PCI bus ID for Intel GPU
mySystem.nvidia.nvidiaBusId   # PCI bus ID for NVIDIA GPU
mySystem.laptop.battery.startChargeThreshold  # Default: 75
mySystem.laptop.battery.stopChargeThreshold   # Default: 80
```
Bus IDs are defined as `mySystem.nvidia.*` options in `hosts/laptop/modules/nvidia.nix` and can be overridden in the laptop's `configuration.nix`.

---

## Adding a New Host

1. Copy existing host: `cp -r hosts/desktop hosts/<new-hostname>`
2. Replace `hardware-configuration.nix` from target machine (`/etc/nixos/`)
3. Add host entry to `hosts/_inventory.nix` with `hostname`, `stateVersion`, and `enabled = true`
4. Adjust `mySystem.*` options in `configuration.nix` for hardware
5. Set `services.avahi.allowInterfaces` to the correct network interface
6. Create/modify `modules/` for hardware-specific needs
7. Deploy: `just nixos` (or `nh os switch --hostname <new-hostname>`)

---

## Configuration Pattern

Every host `configuration.nix` follows the same structure:
```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix  # Auto-generated
    ./local-packages.nix          # Host packages
    ../common-host-info.nix       # Enables hostInfo
    ../../nixos/modules           # Shared modules
    ./modules                     # Host-specific modules
  ];

  mySystem = {
    hostProfile = "desktop";      # or "laptop" — sets defaults via host-defaults.nix
    # Override specific defaults as needed
  };
}
```

**Note**: `common-host-info.nix` sets `mySystem.hostInfo.enable = true` for all hosts, which configures hostname and stateVersion from flake arguments.

**Key rule**: Set `mySystem.hostProfile` and override only what differs from profile defaults.
