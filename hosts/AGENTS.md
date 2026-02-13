# Host Configurations

Two hosts consuming the factory pattern. Each sets `mySystem.hostProfile` for profile-based defaults (via `host-defaults.nix`) and overrides specific options as needed.

---

## Host Comparison

| Setting | pc (desktop) | thinkpad (laptop) |
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

### ThinkPad modules
- `boot.nix` — Kernel params (`acpi_backlight=native`)
- `nvidia.nix` — Optimus offload mode (bus IDs from flake)
- `power.nix` — Disables power-profiles-daemon, loads ThinkPad kernel modules
- `tlp.nix` — Battery thresholds, CPU governor, WiFi power saving

---

## Host-Specific Options

ThinkPad defines extra options not used by pc:
```nix
mySystem.nvidia.intelBusId    # PCI bus ID for Intel GPU
mySystem.nvidia.nvidiaBusId   # PCI bus ID for NVIDIA GPU
mySystem.thinkpad.battery.startChargeThreshold  # Default: 75
mySystem.thinkpad.battery.stopChargeThreshold   # Default: 80
```
Bus IDs are defined as `mySystem.nvidia.*` mkOption in `hosts/thinkpad/modules/nvidia.nix` and set in the ThinkPad's `configuration.nix`.

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
