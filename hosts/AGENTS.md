# Host Configurations

Active host: `pc`. Dormant host: `laptop` (commented out in `flake.nix`, kept for future use).

Each host sets `mySystem.hostProfile` for profile-based defaults (via `host-defaults.nix`) and overrides specific options as needed.

---

## Host Comparison

| Setting | pc (desktop) | laptop (dormant) |
|---------|-------------|-------------------|
| Gaming | enabled + Gamescope | disabled |
| Bluetooth | disabled | enabled (manual start) |
| NVIDIA Optimus | — | Intel + NVIDIA hybrid |
| Power mgmt | minimal | TLP (charge limits 75-80%) |
| Monitor | `1920x1080@144` | `preferred,auto,1` |
| Avahi interface | `eno1` (ethernet) | `wlp0s20f3` (WiFi) |
| Sandboxing | enabled | enabled |
| Privacy stack | full (VPN, Tor, DNS, MAC) | full (VPN, Tor, DNS, MAC) |

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
- No host-specific modules (empty `default.nix` — desktop needs no hardware overrides)

### Laptop modules
- `boot.nix` — Kernel params (`acpi_backlight=native`, `nvidia_drm.fbdev=1`)
- `nvidia.nix` — Optimus offload mode (bus IDs from flake, fine-grained power mgmt)
- `power.nix` — Disables power-profiles-daemon, loads laptop kernel modules (thinkpad_acpi, tp_smapi)
- `tlp.nix` — Battery thresholds (75-80%), CPU governor, WiFi power saving
- `thermal.nix` — thermald for Intel DPTF thermal zone management

---

## Host-Specific Options

Laptop defines extra options not used by pc:
```nix
mySystem.nvidia.intelBusId    # PCI bus ID for Intel GPU
mySystem.nvidia.nvidiaBusId   # PCI bus ID for NVIDIA GPU
mySystem.laptop.battery.startChargeThreshold  # Default: 75
mySystem.laptop.battery.stopChargeThreshold   # Default: 80
```
Bus IDs are defined as `mySystem.nvidia.*` mkOption in `hosts/laptop/modules/nvidia.nix` and set in the laptop's `configuration.nix`.

---

## Adding a New Host

1. Copy existing host: `cp -r hosts/pc hosts/<new-hostname>`
2. Replace `hardware-configuration.nix` from target machine (`/etc/nixos/`)
3. Add to `hosts` list in `flake.nix` with `hostname` and `stateVersion`
4. Adjust `mySystem.*` options in `configuration.nix` for hardware
5. Set `services.avahi.allowInterfaces` to the correct network interface
6. Create/modify `modules/` for hardware-specific needs
7. Deploy: `just nixos` (or `nh os switch --hostname <new-hostname>`)

---

## Configuration Pattern

Every host `configuration.nix` follows the same structure:
```nix
{ stateVersion, hostname, ... }:
{
  imports = [
    ./hardware-configuration.nix  # Auto-generated
    ./local-packages.nix          # Host packages
    ../../nixos/modules           # Shared modules (~52)
    ./modules                     # Host-specific modules
  ];

  # Host identity managed by nixos/modules/host-info.nix
  mySystem = {
    hostInfo.enable = true;       # Sets networking.hostName and system.stateVersion from flake args
    hostProfile = "desktop";      # or "laptop" — sets defaults via host-defaults.nix
    # Override specific defaults as needed
  };
}
```

**Key rule**: Set ALL `mySystem.*` options explicitly. No reliance on defaults for clarity.
