# NixOS System Modules

~52 shared modules imported by all hosts via `default.nix`. Each module handles one subsystem.
Directories (`cleanup/`, `security/`) contain sub-modules imported via their own `default.nix`.

---

## Module Categories

### Core System
| Module | Purpose | Custom Options |
|--------|---------|----------------|
| `bootloader.nix` | GRUB/systemd-boot configuration | None |
| `nix.nix` | Nix package manager settings (flakes, gc) | None |
| `nh.nix` | Nix Helper — build tool wrapper | None |
| `users.nix` | User accounts and permissions | None |
| `environment.nix` | System-wide env vars and paths | None |
| `i18n.nix` | Locale and internationalization | None |
| `timezone.nix` | Time zone configuration | None |
| `stability.nix` | System stability optimizations | None |
| `cleanup/` | Automated cleanup timers (downloads, caches, Docker, Telegram) | `mySystem.cleanup.enable` |
| `host-defaults.nix` | Profile-based defaults (desktop/laptop) for all `mySystem.*` options | `mySystem.hostProfile` |
| `host-info.nix` | Sets hostname and stateVersion from flake arguments | `mySystem.hostInfo.enable` |
| `backup.nix` | Automated restic backup service | `mySystem.backup.*` |

### Security & Privacy
| Module | Purpose | Custom Options |
|--------|---------|----------------|
| `security/` | Kernel hardening, firewall, Avahi, audit timers (split into hardening, firewall, services, audit) | None (always-on) |
| `sandboxing.nix` | Firejail, bubblewrap | `mySystem.sandboxing.*` |
| `tor.nix` | Tor SOCKS proxy (9050/9150) | `mySystem.tor.enable` |
| `mullvad-vpn.nix` | Mullvad VPN client | `mySystem.mullvadVpn.enable` |
| `dnscrypt-proxy.nix` | Encrypted DNS with DNSSEC | `mySystem.dnscryptProxy.enable` |
| `sops.nix` | Secret management (age encryption) | None (always-on) |

### Hardware & Desktop
| Module | Purpose | Custom Options |
|--------|---------|----------------|
| `nvidia.nix` | NVIDIA GPU drivers, CUDA, Wayland integration | `mySystem.nvidia.enable` |
| `audio.nix` | PipeWire audio stack | None (always-on) |
| `bluetooth.nix` | Bluetooth services | `mySystem.bluetooth.*` |
| `niri.nix` | Niri compositor (scrollable tiling Wayland) system integration | None |
| `greetd.nix` | greetd display manager with tuigreet | `mySystem.greetd.enable` |
| `xserver.nix` | X11 display server | None |
| `xdg-desktop-portal.nix` | XDG portals for Wayland | None |
| `libinput.nix` | Touchpad/mouse input | None |
| `upower.nix` | Power/battery monitoring | None |
| `printing.nix` | CUPS print services | `mySystem.printing.enable` |
| `monitoring.nix` | Hardware sensors, vnStat, bandwhich | None |

### Observability Stack
| Module | Purpose | Custom Options |
|--------|---------|----------------|
| `netdata.nix` | Real-time system monitoring dashboard | `mySystem.netdata.enable` |
| `scrutiny.nix` | SMART disk health monitoring | `mySystem.scrutiny.enable` |
| `glance.nix` | Minimal dashboard with Gruvbox theme (localhost:8082) | `mySystem.glance.enable` |
| `opensnitch.nix` | Application firewall with network logging | `mySystem.opensnitch.enable` |
| `loki.nix` | Loki log aggregation with Promtail | `mySystem.loki.enable` |
| `prometheus-grafana.nix` | Prometheus + Grafana observability stack | `mySystem.observability.enable` |

### Applications & Services
| Module | Purpose | Custom Options |
|--------|---------|----------------|
| `gaming.nix` | Steam, Lutris, Wine, MangoHud | `mySystem.gaming.*` |
| `flatpak.nix` | Flatpak + Flathub | `mySystem.flatpak.enable` |
| `virtualisation.nix` | Docker, libvirt/QEMU | `mySystem.virtualisation.enable` |
| `networking.nix` | NetworkManager, firewall rules | None |
| `nix-ld.nix` | Dynamic linker for non-Nix binaries | `mySystem.nixLd.enable` |
| `nautilus.nix` | GNOME Files manager | `mySystem.nautilus.enable` |
| `android.nix` | Android tools and platform support | None |
| `browser-deps.nix` | Chrome/Chromium dependencies (Wayland + X11) | None |
| `waydroid.nix` | Waydroid Android emulation (LXC container) | `mySystem.waydroid.enable` |

### Cross-Cutting
| Module | Purpose |
|--------|---------|
| `validation.nix` | **CRITICAL**: Cross-module conflict assertions |

---

## Directory Modules

### `cleanup/`
Split into sub-modules. Guarded by `mySystem.cleanup.enable`.
| Sub-module | Purpose |
|------------|---------|
| `default.nix` | Import hub + `mySystem.cleanup.enable` option definition |
| `lib.nix` | Reusable `mkCleanupTimer` helper (imported manually by sub-modules, not in `default.nix`) |
| `downloads.nix` | Download, screenshot, Telegram, and clipboard cleanup timers |
| `cache.nix` | Cache cleanup timers (pip, npm, bun, go, Playwright), Docker prune |

### `security/`
Split from monolithic `security.nix`. Always-on (no enable guard).
| Sub-module | Purpose |
|------------|---------|
| `default.nix` | Import hub |
| `hardening.nix` | sysctl hardening, PAM core dumps, AppArmor, sudo, hidepid, coredump |
| `firewall.nix` | `networking.firewall` block |
| `services.nix` | dbus broker, Avahi (authoritative config), systemd Manager timeouts |
| `audit.nix` | security-audit timer + service (weekly Lynis scan) |
| `audit-logging.nix` | Security event logging with fail2ban (`mySystem.auditLogging.enable`) |
| `opsec.nix` | Operational security (MAC randomization, kexec, metadata, zram, NTS, Thunderbolt) |

---

## Host Defaults System (host-defaults.nix)

Defines `mySystem.hostProfile` (enum: `"desktop"` | `"laptop"`).
Sets `lib.mkDefault` for all shared `mySystem.*` options so hosts only need to set the profile + overrides.

| Option | Desktop Default | Laptop Default |
|--------|-----------------|----------------|
| `gaming.enable` | `true` | `false` |
| `gaming.enableGamescope` | `true` | `false` |
| `bluetooth.enable` | `false` | `true` |
| `bluetooth.powerOnBoot` | `false` | `false` |
| `backup.enable` | `false` | `false` |
| `auditLogging.enable` | `false` | `false` |
| All others (sandboxing, flatpak, mullvadVpn, tor, dnscryptProxy, printing, virtualisation, nautilus, nixLd, cleanup, glance, netdata, opensnitch, scrutiny, waydroid, greetd, nvidia, observability, loki) | `true` | `true` |

Host configs only need:
```nix
mySystem.hostProfile = "desktop"; # or "laptop"
# Override specific defaults as needed
```

---

## Option Pattern Quick Reference

Modules with `mySystem.*` options use the **enable-guard** pattern:
```nix
config = lib.mkIf config.mySystem.<feature>.enable { ... };
```

Modules **without** custom options apply unconditionally (audio, security, networking).

### inherit Pattern for Sub-Options
```nix
# Pass option value directly to NixOS config
hardware.bluetooth = {
  enable = true;
  inherit (config.mySystem.bluetooth) powerOnBoot;
};
```

---

## Validation Dependencies (validation.nix)

| If Enabled | Requires | Error If Missing |
|------------|----------|------------------|
| `mySystem.gaming` | `hardware.graphics.enable` | Graphics drivers required |
| `mySystem.gaming` | `services.pipewire.pulse.enable` | PipeWire with PulseAudio compat |
| `mySystem.mullvadVpn` | `networking.networkmanager.enable` | NetworkManager required |
| `mySystem.sandboxing` | `kernel.unprivileged_userns_clone = 1` | User namespaces required |
| `mySystem.dnscryptProxy` | `!services.resolved.enable` | Conflicts with systemd-resolved |
| Any config | `networking.firewall.enable` | Firewall mandatory |
| `services.avahi` | `allowInterfaces != []` | Explicit interface list required |

---

## Adding a New Module

1. Create `nixos/modules/<name>.nix` following canonical pattern (see root AGENTS.md)
2. Add import with comment to `nixos/modules/default.nix`
3. If feature is optional: define `options.mySystem.<name>.enable` + guard with `lib.mkIf`
4. If feature has cross-module deps: add assertion to `validation.nix`
5. If feature should be on by default: add `mkDefault` entry to `host-defaults.nix`
6. Enable/override in host configs: `hosts/*/configuration.nix`
7. Run: `just modules && just lint && just format && just check`
