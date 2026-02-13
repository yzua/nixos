# NixOS System Configuration

Flake-based NixOS + Home Manager config with Niri compositor (scrollable tiling Wayland), Noctalia Shell, Gruvbox theming, and a full privacy/monitoring stack.

---

## Using This Config

### Prerequisites

- NixOS installed with flakes enabled
- Git, age key for secrets

### Step 1: Clone

```bash
git clone <repo-url> ~/System
cd ~/System
```

### Step 2: Set your identity

Edit `shared/constants.nix` — this is the single source of truth for your personal settings:

```nix
# shared/constants.nix
{
  user = {
    handle = "yourname";          # Unix username (must match flake.nix user)
    name = "Your Name";           # Git commit author
    email = "you@example.com";    # Git commit email
    githubEmail = "...@users.noreply.github.com";  # GitHub noreply email
    signingKey = "0xYOURKEY";     # GPG signing key ID
  };

  terminal = "ghostty";           # Your terminal emulator
  terminalAppId = "com.mitchellh.ghostty";  # Wayland app-id (for window rules)
  editor = "code";                 # Your editor
  editorAppId = "code-url-handler"; # Wayland app-id

  font = {
    mono = "JetBrains Mono";
    size = 13;
  };

  # Keyboard layout, theme, colors — adjust as needed
  # ...
}
```

### Step 3: Set your username in `flake.nix`

```nix
# flake.nix (line 52)
user = "yourname";  # Must match constants.user.handle
```

### Step 4: Create your host

```bash
cp -r hosts/pc hosts/<your-hostname>
cp /etc/nixos/hardware-configuration.nix hosts/<your-hostname>/
```

### Step 5: Configure your host

Edit `hosts/<your-hostname>/configuration.nix`:

```nix
{ stateVersion, hostname, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  mySystem = {
    hostInfo.enable = true;           # Sets hostname + stateVersion from flake
    hostProfile = "desktop";          # "desktop" or "laptop"
    # Override defaults as needed:
    # nvidia.enable = false;          # No NVIDIA GPU
    # gaming.enable = false;          # No gaming
  };

  services.avahi.allowInterfaces = [ "eno1" ];  # Your network interface
}
```

### Step 6: Register the host in `flake.nix`

Add to the `hosts` list:

```nix
hosts = [
  { hostname = "your-hostname"; stateVersion = "25.11"; }
];
```

### Step 7: Setup secrets and deploy

```bash
just sops-setup          # Create age key
just sops-edit           # Add your secrets (API keys, etc.)
just all                 # Full pipeline: lint -> format -> check -> build -> switch
```

---

## Commands

| Command | What it does |
|---------|-------------|
| `just all` | Full pipeline: modules -> lint -> format -> check -> nixos -> home |
| `just home` | Apply Home Manager config (safe, user-level) |
| `just nixos` | Apply NixOS config (system-level) |
| `just modules` | Validate default.nix imports match files on disk |
| `just lint` | statix + deadnix + shellcheck |
| `just format` | nixfmt-tree |
| `just check` | `nix flake check --no-build` |
| `just update` | Update all flake inputs |
| `just clean` | GC old generations |
| `just diff` | Diff current vs previous NixOS generation |
| `just sops-edit` | Edit encrypted secrets |
| `just sops-view` | View decrypted secrets |

### Development workflow

```bash
# Edit -> validate -> test -> apply
vim nixos/modules/my-module.nix
just modules    # Fast import check
just lint       # Linting
just format     # Auto-format
just check      # Flake evaluation
just home       # User-level (safe, try first)
just nixos      # System-level (last)
```

---

## System Options (`mySystem.*`)

All features toggle via `mySystem.*` options. Set `hostProfile` and most default to `true`:

| Option | Description |
|--------|-------------|
| `hostProfile` | `"desktop"` or `"laptop"` — sets defaults for everything below |
| `hostInfo.enable` | Hostname and stateVersion from flake args |
| `nvidia.enable` | NVIDIA GPU drivers, CUDA, Wayland |
| `gaming.enable` | Steam, Lutris, Wine, MangoHud |
| `gaming.enableGamescope` | Gamescope compositor for Steam |
| `bluetooth.enable` | Bluetooth services |
| `sandboxing.enable` | Firejail, bubblewrap |
| `mullvadVpn.enable` | Mullvad VPN |
| `tor.enable` | Tor SOCKS proxy |
| `dnscryptProxy.enable` | Encrypted DNS with DNSSEC |
| `virtualisation.enable` | Docker, libvirt/QEMU |
| `flatpak.enable` | Flatpak + Flathub |
| `printing.enable` | CUPS |
| `nautilus.enable` | GNOME Files |
| `nixLd.enable` | Dynamic linker for non-Nix binaries |
| `cleanup.enable` | Automated cleanup timers |
| `backup.enable` | Restic backups |
| `netdata.enable` | System monitoring (localhost:19999) |
| `scrutiny.enable` | Disk health (localhost:8080) |
| `glance.enable` | Dashboard (localhost:8082) |
| `opensnitch.enable` | Application firewall |
| `observability.enable` | Prometheus + Grafana |
| `loki.enable` | Log aggregation |
| `greetd.enable` | Display manager |
| `waydroid.enable` | Android emulation |
| `auditLogging.enable` | fail2ban logging |

Desktop profile enables gaming + Gamescope. Laptop enables bluetooth. Both default everything else to `true`.

---

## Security

Always-on (no toggle): kernel hardening, AppArmor, MAC randomization, zram swap, hidepid=2.

Toggleable: Firejail sandboxing, Mullvad VPN, Tor, DNSCrypt, OpenSnitch firewall, fail2ban audit logging.

---

## Monitoring

All local, no cloud. Toggle each via `mySystem.*`:

| Service | URL | Purpose |
|---------|-----|---------|
| Netdata | localhost:19999 | Real-time system metrics |
| Scrutiny | localhost:8080 | SMART disk health |
| Glance | localhost:8082 | Dashboard (services, RSS, crypto) |
| Grafana | localhost:3001 | Custom dashboards |
| Prometheus | localhost:9090 | Metrics/alerting |
| ActivityWatch | localhost:5600 | App usage tracking |
| Syncthing | localhost:8384 | File sync |

CLI: `vnstat` (bandwidth), `bandwhich` (per-process), `nvitop` (GPU).

---

## Project Structure

```
flake.nix                     # Entry point, host factory, specialArgs
shared/constants.nix          # User identity, terminal, editor, font, theme, keyboard
hosts/<hostname>/
  configuration.nix           # Host config (mySystem.* options)
  hardware-configuration.nix  # Auto-generated (never edit)
  local-packages.nix          # Host-specific packages
  modules/                    # Host-specific hardware modules
nixos/modules/                # ~52 shared system modules
  cleanup/                    # Automated cleanup timers (downloads, caches)
  security/                   # Kernel hardening, firewall, AppArmor, opsec
  host-defaults.nix           # Profile defaults (desktop/laptop)
  host-info.nix               # Hostname + stateVersion management
  validation.nix              # Cross-module conflict assertions
  ...                         # One module per subsystem
home-manager/
  home.nix                    # HM entry point (standalone, not NixOS module)
  modules/
    ai-agents/                # AI coding agents (Claude Code, OpenCode, Codex, Gemini)
    apps/                     # App configs (OBS, KeePassXC, Discord, ActivityWatch, etc.)
    niri/                     # Niri compositor (input, layout, rules, binds, scripts)
    noctalia/                 # Noctalia Shell (bar, settings)
    neovim/                   # Neovim with LSP and plugins
    languages/                # Go, JS/TS, Python, LSP servers, Mise
    terminal/                 # Ghostty, Zellij, Zsh, CLI tools, scripts
    stylix.nix                # Gruvbox theming
  packages/                   # 12 domain chunks (cli, dev, multimedia, privacy, etc.)
scripts/                      # Utility scripts (ai, browser, build, sops)
secrets/secrets.yaml          # Encrypted secrets (sops-nix, age)
devShells/                    # Per-language dev environments (Node, Python, Rust, Go, etc.)
```

---

## Secrets

Uses `sops-nix` with age encryption. Private key at `~/.config/sops/age/keys.txt`.

```bash
just sops-setup    # Create age key
just sops-edit     # Edit secrets (auto encrypt/decrypt)
just sops-view     # View decrypted
just secrets-add key value  # Add single secret
```
