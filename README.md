# NixOS System Configurations

This repository contains my personal NixOS system configurations, managed with Nix Flakes. It features a complete desktop environment with Niri compositor (scrollable tiling Wayland), Noctalia Shell, beautiful Gruvbox theming, extensive development tooling, and AI-powered development utilities.

---

## Quick Start

### Installation
```bash
# Clone repository
git clone git@github.com:82163/nixos-config.git ~/System
cd ~/System

# Apply configuration (runs full pipeline: modules check, lint, format, flake check, nixos switch, home-manager switch)
just all
```

### Onboarding a New Machine

#### 1. Clone repo:
```bash
git clone git@github.com:82163/nixos-config.git ~/System
cd ~/System
```

#### 2. Create host configuration:
```bash
cd hosts
cp -r pc <new-hostname>
```

#### 3. Copy hardware configuration:
```bash
cp /etc/nixos/hardware-configuration.nix hosts/<new-hostname>/
```

#### 4. Add new host to `flake.nix`:
Open `flake.nix` and add your new host to the `hosts` list with appropriate configuration.

#### 5. Deploy system:
```bash
# For new host (using modern nh)
nh os switch --flake ~/System#<new-hostname>
nh home switch --flake ~/System#yz

# Or use just commands:
just nixos
just home
```

---

## Secrets Management

This configuration uses `sops-nix` for managing encrypted secrets with age keys.

### Quick Start
```bash
# Setup age key (if not already done)
just sops-setup

# View current secrets
just sops-view

# Edit secrets (opens editor with auto encrypt/decrypt)
just sops-edit

# Add single secret
just secrets-add github_token ghp_your_token_here
```

### Available Commands
| Command | Purpose |
|---------|---------|
| `just sops-view` | View decrypted secrets |
| `just sops-edit` | Edit secrets (opens editor) |
| `just secrets-add key value` | Add single secret |
| `just sops-decrypt` | Decrypt to file for manual editing |
| `just sops-encrypt` | Encrypt file back to secrets |
| `just sops-key` | Show public key |
| `just sops-setup` | Setup age key |

### Security Notes
- Secrets are encrypted at rest using age encryption
- Private keys are stored in `~/.config/sops/age/keys.txt`
- Never commit private keys or decrypted secrets to Git
- Use `just sops-edit` for most editing (automatic encrypt/decrypt)

---

## Available Commands

| Command | Purpose |
|---------|---------|
| `just` | List all available commands |
| `just all` | **Run full pipeline**: modules, lint, format, flake check, nixos, home |
| `just nixos` | Rebuild and switch NixOS configuration using **nh** (modern Nix helper) |
| `just home` | Apply Home Manager configuration using **nh** (safe, user-level only) |
| `just format` | Format all `.nix` files with `nixfmt-tree` (fast directory-wide formatting) |
| `just lint` | Lint all `.nix` files with `statix` + `deadnix` + bash `shellcheck` |
| `just dead` | Scan for unused code in `.nix` files with `deadnix` |
| `just check` | Run `nix flake check --no-build` to validate flake schema and syntax |
| `just modules` | Check for missing module imports (**critical before commits**) |
| `just update` | Update all flake inputs |
| `just clean` | Clean old generations and optimize Nix store using **nh** |
| `just diff` | Show what changed between current and previous NixOS generation |
| `just setup-keys` | Setup SSH and GPG keys from SOPS |
| `just sops-*` | Secret management commands (view, edit, add, decrypt, encrypt, key, setup) |

---

## System Configuration Options

This configuration uses a custom `mySystem` namespace pattern for organizing optional system-level features.

### Available Options

| Option | Description |
|---------|-------------|
| `mySystem.hostInfo.enable` | Automatic hostname and stateVersion from flake arguments |
| `mySystem.hostProfile` | Host profile (`"desktop"` or `"laptop"`) — sets sensible defaults for all options below |
| `mySystem.gaming.enable` | Enable gaming support (Steam, Lutris, Wine, MangoHud) |
| `mySystem.gaming.enableGamescope` | Enable Gamescope compositor session for Steam |
| `mySystem.sandboxing.enable` | Enable application sandboxing (Firejail, bubblewrap) |
| `mySystem.sandboxing.enableUserNamespaces` | Enable user namespaces for sandboxing |
| `mySystem.sandboxing.enableWrappedBinaries` | Enable automatic Firejail wrapping for common apps |
| `mySystem.flatpak.enable` | Enable Flatpak support with Flathub |
| `mySystem.bluetooth.enable` | Enable Bluetooth services and device management |
| `mySystem.bluetooth.powerOnBoot` | Enable Bluetooth power on boot |
| `mySystem.mullvadVpn.enable` | Enable Mullvad VPN client integration |
| `mySystem.tor.enable` | Enable Tor network services and SOCKS proxy |
| `mySystem.dnscryptProxy.enable` | Enable DNSCrypt-Proxy for encrypted DNS |
| `mySystem.printing.enable` | Enable CUPS printing services |
| `mySystem.virtualisation.enable` | Enable Docker and libvirt/QEMU virtualisation |
| `mySystem.nautilus.enable` | Enable GNOME Files (Nautilus) file manager |
| `mySystem.nixLd.enable` | Enable dynamic linker for non-Nix binaries |
| `mySystem.cleanup.enable` | Enable automated cleanup timers (downloads, caches, Docker) |
| `mySystem.netdata.enable` | Enable Netdata real-time system monitoring dashboard |
| `mySystem.opensnitch.enable` | Enable OpenSnitch application firewall with per-app network logging |
| `mySystem.scrutiny.enable` | Enable Scrutiny SMART disk health monitoring dashboard at localhost:8080 |
| `mySystem.glance.enable` | Enable Glance minimal dashboard with Gruvbox theme at localhost:8082 |
| `mySystem.observability.enable` | Enable Prometheus + Grafana observability stack |
| `mySystem.loki.enable` | Enable Loki log aggregation with Promtail |
| `mySystem.waydroid.enable` | Enable Waydroid Android emulation |
| `mySystem.greetd.enable` | Enable greetd display manager with tuigreet |
| `mySystem.nvidia.enable` | Enable NVIDIA GPU drivers, CUDA, and Wayland integration |
| `mySystem.backup.enable` | Enable automated restic backup service (requires sops secret) |
| `mySystem.auditLogging.enable` | Enable security event logging with fail2ban |

### Example Configuration

In your host configuration file (`hosts/*/configuration.nix`):

```nix
# Set the host profile — this sets sensible defaults for all mySystem.* options
mySystem.hostProfile = "desktop"; # or "laptop"

# Override specific defaults as needed
mySystem.gaming.enableGamescope = true;
mySystem.sandboxing.enableUserNamespaces = true;
```

Most options default to `true` via `host-defaults.nix` when a profile is set.
Desktop profile enables gaming; laptop profile enables bluetooth.

---

## Security Hardening

GrapheneOS-inspired security features for defense-in-depth:

| Feature | Description |
|---------|-------------|
| **Hardened Malloc** | GrapheneOS memory allocator with heap exploit mitigations |
| **Auto-lock** | Screen locks after 5 minutes idle |
| **Kernel Hardening** | ptrace restriction, BPF hardening, kptr hiding, hidepid=2 |
| **MAC Randomization** | Random MAC addresses on network connection |
| **DNSCrypt** | Encrypted DNS with DNSSEC validation |
| **OpenSnitch** | Per-app firewall with default-deny option |
| **Firejail** | Sandbox for browsers and messaging apps |
| **AppArmor** | Mandatory access control for system services |
| **zram Swap** | RAM-based swap (no disk swap) to prevent data leakage |

---

## Monitoring & Analytics

A 24/7 monitoring stack tracks app usage, system metrics, and network activity — all data stays local.

### Dashboards

| Service | URL | What It Shows |
|---------|-----|---------------|
| **Glance** | http://localhost:8082 | Minimal dashboard: services, Docker, Hacker News, Lobsters, crypto, RSS feeds |
| **Netdata** | http://localhost:19999 | Real-time CPU, RAM, disk, network, GPU, per-process metrics with historical graphs |
| **Scrutiny** | http://localhost:8080 | SMART disk health, historical trends, and real-world failure thresholds |
| **Grafana** | http://localhost:3001 | Visualization dashboards for metrics and logs |
| **Prometheus** | http://localhost:9090 | Metrics collection, alerting, and time-series database |
| **ActivityWatch** | http://localhost:5600 | App usage timelines, daily summaries, category breakdowns, browser activity |
| **Syncthing** | http://localhost:8384 | Decentralized file sync (home-manager service) |

### Terminal Commands

| Command | What It Shows |
|---------|---------------|
| `vnstat` | Today's bandwidth summary |
| `vnstat -d` | Daily bandwidth history |
| `vnstat -m` | Monthly bandwidth history |
| `vnstat -l` | Live traffic monitor |
| `bandwhich` | Real-time per-process bandwidth (no sudo needed) |
| `nvitop` | Interactive NVIDIA GPU monitor (better than nvidia-smi) |

### OpenSnitch (Application Firewall)

The OpenSnitch tray icon appears in the system tray. Click it to:
- View all per-app network connections in real-time
- See connection statistics per application
- Create allow/deny rules for specific apps

For web activity tracking in ActivityWatch, install the browser extension:
- **Firefox**: search "ActivityWatch" in Add-ons
- **Brave/Chrome**: search "ActivityWatch" in Chrome Web Store

### Service Health Check

```bash
# System services
systemctl status netdata
systemctl status scrutiny
systemctl status opensnitch
systemctl status vnstatd

# User services (Home Manager)
systemctl --user status activitywatch
systemctl --user status activitywatch-watcher-awatcher
systemctl --user status opensnitch-ui
```

### Configuration

| Component | NixOS Module | Home Manager Module |
|-----------|-------------|-------------------|
| Glance | `nixos/modules/glance.nix` | — |
| Netdata | `nixos/modules/netdata.nix` | — |
| Scrutiny | `nixos/modules/scrutiny.nix` | — |
| OpenSnitch | `nixos/modules/opensnitch.nix` | `home-manager/modules/apps/opensnitch-ui.nix` |
| vnStat + bandwhich | `nixos/modules/monitoring.nix` | — |
| ActivityWatch | — | `home-manager/modules/apps/activitywatch.nix` |

---

## Development Workflow

For making changes:

```bash
# 1. Make your changes
vim nixos/modules/security/hardening.nix

# 2. Check for missing module imports
just modules

# 3. Format files
just format

# 4. Scan for dead code
just dead

# 5. Lint files
just lint

# 6. Validate flake
just check

# 7. Test changes (user-level first)
just home

# 8. Apply system changes
just nixos
```

---

## Flake Inputs

This configuration uses the following flakes:

- **nixpkgs** - NixOS unstable packages
- **nixpkgs-stable** - NixOS 25.11 stable packages
- **home-manager** - User environment management
- **stylix** - System theming and styling (Gruvbox theme)
- **sops-nix** - Secret management with age encryption
- **niri** - Niri compositor (scrollable tiling Wayland)
- **noctalia** - Noctalia Shell (all-in-one desktop shell)
- **nixcord** - Declarative Discord (Vesktop + Vencord)
- **nix-index-database** - Pre-built nix-index database for instant lookups
<!-- lanzaboote (Secure Boot) — removed from flake, re-add when needed -->

---

## Project Structure

```
.
├── devShells/                     ← Project development environments
│   ├── bun/                       ← Bun runtime environment
│   ├── deno/                      ← Deno runtime environment
│   ├── nodejs/                    ← Node.js environment
│   ├── postgresql/                ← PostgreSQL development
│   ├── python-venv/               ← Python virtual environment
│   ├── rust-stable/               ← Rust stable toolchain
│   └── rust-nightly/              ← Rust nightly toolchain
├── home-manager/                  ← Home Manager configuration
│   ├── home.nix                   ← HM entry point (standalone, not NixOS module)
│   ├── modules/                   ← Reusable home-manager modules
│   │   ├── ai-agents/             ← AI coding agent config (Claude Code, OpenCode, Codex, Gemini CLI)
│   │   │   ├── default.nix        ← Module options, MCP servers, logging, activation scripts
│   │   │   ├── config.nix         ← Actual agent configuration values
│   │   │   └── log-analyzer.nix   ← AI agent log analysis and dashboard
│   │   ├── apps/                  ← Application configs (OBS, Syncthing, KeePassXC, Discord, ActivityWatch, etc.)
│   │   ├── niri/                  ← Niri compositor (scrollable tiling Wayland)
│   │   │   ├── default.nix        ← Import hub
│   │   │   ├── main.nix           ← Compositor settings (autostart, workspaces, environment)
│   │   │   ├── binds.nix          ← Keybindings and custom scripts
│   │   │   ├── input.nix          ← Input devices (keyboard, mouse, touchpad)
│   │   │   ├── layout.nix         ← Layout settings (columns, gaps, focus)
│   │   │   ├── rules.nix          ← Window rules (opacity, floating, workspace assignments)
│   │   │   ├── idle.nix           ← Idle management (DPMS, lock)
│   │   │   ├── lock.nix           ← Screen locker
│   │   │   └── scripts/           ← Extracted helper scripts (color-picker, books, screenshot)
│   │   ├── noctalia/              ← Noctalia Shell (bar, launcher, notifications, lock, wallpaper, OSD)
│   │   │   ├── default.nix        ← Import hub
│   │   │   ├── bar.nix            ← Bar widgets configuration
│   │   │   └── settings.nix       ← Shell settings (theme, dock, wallpaper, OSD, hooks)
│   │   ├── neovim/                ← Neovim editor with LSP, completion, and modern plugins
│   │   │   ├── default.nix        ← Plugin declarations, treesitter, Lua config loading
│   │   │   ├── lua/               ← Lua configuration (options, keymaps, LSP, plugins)
│   │   │   └── plugins/           ← Plugin-specific configs (wakatime)
│   │   ├── languages/             ← Language tooling (Go, JS, Python, LSP servers, Mise)
│   │   ├── terminal/              ← Terminal, shell, and CLI tools
│   │   │   ├── ghostty.nix        ← Ghostty terminal emulator
│   │   │   ├── zellij.nix         ← Terminal multiplexer
│   │   │   ├── direnv.nix         ← Per-directory environments
│   │   │   ├── scripts.nix        ← Custom utility scripts (ai-ask, ai-help, etc.)
│   │   │   ├── shell.nix          ← Nix shell integration and dev tools
│   │   │   ├── zsh/               ← Zsh + Oh My Zsh (oxide theme, aliases)
│   │   │   └── tools/             ← CLI tools (atuin, bat, btop, carapace, cava, eza, fzf, git, htop, lazygit, starship, yazi, zathura, zoxide)
│   │   ├── browser-isolation.nix  ← Browser sandboxing and Tor routing
│   │   ├── gpg.nix                ← GPG key management
│   │   ├── mime.nix               ← MIME type associations
│   │   ├── qt.nix                 ← Qt theming
│   │   └── stylix.nix             ← System theming (Gruvbox)
│   └── packages/                  ← Grouped package lists (12 domain chunks)
│       ├── applications.nix
│       ├── cli.nix
│       ├── custom/
│       │   └── prayer.nix         ← Islamic prayer times
│       ├── development.nix
│       ├── gnome.nix
│       ├── multimedia.nix
│       ├── networking.nix
│       ├── niri.nix
│       ├── privacy.nix
│       ├── productivity.nix
│       ├── system-monitoring.nix
│       └── utilities.nix
├── hosts/                         ← Per-host NixOS configurations
│   ├── pc/                        ← Desktop workstation (NVIDIA)
│   │   ├── configuration.nix      ← Main configuration
│   │   ├── hardware-configuration.nix ← Auto-generated
│   │   ├── local-packages.nix     ← Host-specific packages
│   │   └── modules/
│   │       └── default.nix
│   └── thinkpad/                  ← Laptop configuration (TLP power mgmt)
│       ├── configuration.nix      ← Main configuration
│       ├── hardware-configuration.nix ← Auto-generated
│       ├── local-packages.nix     ← Host-specific packages
│       └── modules/
│           ├── boot.nix
│           ├── nvidia.nix         ← NVIDIA Optimus (hybrid graphics)
│           ├── power.nix
│           └── tlp.nix
├── nixos/                         ← Shared NixOS system modules
│   └── modules/                   ← System-level configurations (~52 modules)
│       ├── android.nix            ← Android tools and platform support
│       ├── audio.nix              ← Audio system (PipeWire)
│       ├── backup.nix             ← Automated restic backup service
│       ├── bluetooth.nix          ← Bluetooth support
│       ├── bootloader.nix         ← Boot loader configuration
│       ├── browser-deps.nix       ← Chrome/Chromium dependencies (Wayland + X11)
│       ├── cleanup/               ← Automated cleanup services (downloads, caches, Docker)
│       ├── default.nix            ← Module imports
│       ├── dnscrypt-proxy.nix     ← DNSCrypt-Proxy for encrypted DNS
│       ├── environment.nix        ← Environment variables
│       ├── flatpak.nix            ← Flatpak support with Flathub
│       ├── gaming.nix             ← Gaming (Steam, Lutris, Wine, MangoHud)
│       ├── glance.nix             ← Glance minimal dashboard (Gruvbox theme)
│       ├── greetd.nix             ← greetd display manager with tuigreet
│       ├── host-defaults.nix      ← Profile-based defaults (desktop/laptop)
│       ├── host-info.nix          ← Hostname and stateVersion from flake args
│       ├── i18n.nix               ← Internationalization
│       ├── libinput.nix           ← Input device support
│       ├── loki.nix               ← Loki log aggregation with Promtail
│       ├── monitoring.nix         ← System monitoring, vnStat, bandwhich
│       ├── mullvad-vpn.nix        ← Mullvad VPN configuration
│       ├── nautilus.nix           ← File manager configuration
│       ├── netdata.nix            ← Netdata real-time monitoring dashboard
│       ├── networking.nix         ← Network configuration
│       ├── nh.nix                 ← Nix Helper (nh) configuration
│       ├── niri.nix               ← Niri compositor system integration
│       ├── nix-ld.nix             ← Dynamic linker for non-Nix binaries
│       ├── nix.nix                ← Nix package manager config
│       ├── nvidia.nix             ← NVIDIA GPU drivers, CUDA, Wayland
│       ├── opensnitch.nix         ← OpenSnitch application firewall
│       ├── printing.nix           ← Print services
│       ├── prometheus-grafana.nix ← Prometheus + Grafana observability
│       ├── sandboxing.nix         ← Application sandboxing (Firejail, bubblewrap)
│       ├── scrutiny.nix           ← Scrutiny SMART disk health monitoring
│       ├── security/              ← System security hardening
│       │   ├── default.nix        ← Import hub
│       │   ├── audit.nix          ← Weekly Lynis security audit
│       │   ├── audit-logging.nix  ← Security event logging with fail2ban
│       │   ├── firewall.nix       ← Firewall configuration
│       │   ├── hardening.nix      ← Kernel hardening, PAM, AppArmor, hidepid
│       │   ├── opsec.nix          ← Operational security (MAC, kexec, zram, NTS)
│       │   └── services.nix       ← dbus, Avahi, systemd timeouts
│       ├── sops.nix               ← Secret management
│       ├── stability.nix          ← System stability settings
│       ├── timezone.nix           ← Time zone configuration
│       ├── tor.nix                ← Tor network services
│       ├── upower.nix             ← Power management
│       ├── users.nix              ← User account management
│       ├── validation.nix         ← Cross-module conflict assertions (CRITICAL)
│       ├── virtualisation.nix     ← Docker and libvirt
│       ├── waydroid.nix           ← Waydroid Android emulation
│       ├── xdg-desktop-portal.nix ← XDG desktop portal configuration
│       └── xserver.nix            ← X11 server configuration (XWayland)
├── scripts/                       ← Utility scripts
│   ├── ai/                        ← AI agent helper scripts
│   ├── browser/                   ← Browser automation scripts
│   ├── build/                     ← Build and deployment scripts
│   └── sops/                      ← Secret management scripts
├── secrets/                       ← Encrypted secrets (sops-nix)
│   └── secrets.yaml
├── shared/                        ← Shared configuration constants
│   └── constants.nix              ← Terminal, editor, font, theme, keyboard, user identity
├── themes/                        ← Custom themes and wallpapers
├── AGENTS.md                      ← Guidelines for AI agents (authoritative)
├── .sops.yaml                     ← SOPS encryption rules (age keys, path patterns)
├── .gitignore                     ← Git ignore rules
├── flake.lock                     ← Locked dependency versions
├── flake.nix                      ← Main Nix flake configuration
├── justfile                       ← Task runner commands
└── README.md                      ← This file
```
