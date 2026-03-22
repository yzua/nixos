# NixOS Configuration - Agent Guidelines

## Root Overview

- Flake-based NixOS + Standalone Home Manager.
- Host: `desktop` (active), `laptop` (dormant).
- Env: `x86_64-linux`, Niri (Wayland), Noctalia Shell, Gruvbox (`stylix`).
- Identity: `yz` (`shared/constants.nix`). Terminal: `ghostty`. Editor: `code`.

## Structure Map

- `flake.nix`: Registry, global `pkgConfig`, host factory.
- `hosts/`: Host hardware + `configuration.nix`. `_inventory.nix` for active hosts.
- `nixos/modules/`: System services. `mySystem.*` options.
- `home-manager/`: User config. Modules + package chunks.
- `scripts/`: System reports, AI agent inventory, sops helpers.
- `dev-shells/`: Atomic, per-language Nix shells.
- `AGENTS.md` Hierarchy: Sub-guidance in `nixos/`, `home-manager/`, `scripts/`, etc.

## Commands (Just Pipeline)

### Validation (run before commits, in order)

- `just modules`: Validate `default.nix` imports (fastest check).
- `just pkgs`: Detect duplicate packages/conflicts.
- `just lint`: Statix + Deadnix + Shellcheck + Markdownlint.
- `just dead`: Deadnix only (subset of lint).
- `just format`: `nixfmt-tree` via `nix fmt`.
- `just check`: `nix flake check --no-build` (full evaluation without build).

### Apply changes

- `just home`: Home Manager switch (safe, user-level) — run FIRST.
- `just nixos`: NixOS switch (system-level) — run AFTER `just home`.
- `just all`: Full pipeline: modules → pkgs → lint → format → check → nixos → home.

### Other

- `just update`: Update all flake inputs.
- `just diff`: Diff current vs previous NixOS generation (`nvd`).
- `just clean`: GC old generations + optimize store.
- `just security-audit`: systemd unit hardening + vulnix CVE scan.
- `just report [mode]`: System health report generator.
- `just sops-view` / `just sops-edit` / `just secrets-add KEY`: Secrets management.

### No unit tests

Escalation order: `just modules` (fastest) → `just check` (eval) → `just home` (user build) → `just nixos` (system build, last resort).

## Global Conventions

- **mySystem.\* Pattern**: Enable/configure features via custom options.
- **Canonical Layout**: `options.mySystem.X = { enable = ...; }; config = mkIf cfg.enable { ... };`.
- **Standalone HM**: NOT a NixOS module. Separate lifecycle (`just home`). HM modules cannot reference NixOS `config.*`.
- **Imports**: Every dir requires `default.nix`. No auto-discovery.
- **Helpers**: Prefix with `_` (e.g., `_lib.nix`). Manual imports only.
- **Strictness**: `allowBroken = false` (enforced). No channels. No cloud dependencies.
- **Constants**: Single source of truth in `shared/constants.nix`.

## Code Style

### Nix modules (canonical layout)

```nix
# One-line comment explaining module purpose.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.feature = {
    enable = lib.mkEnableOption "feature description";
  };
  config = lib.mkIf config.mySystem.feature.enable {
    # Implementation
  };
}
```

### Key conventions

- **Formatter**: `nixfmt-tree` — never manually format, run `just format`.
- **Imports**: every directory with `.nix` files must have `default.nix` listing all imports with inline comments.
- **`_` prefix files**: Helper files like `_lib.nix` are imported manually by other modules — NOT listed in `default.nix`.
- **inherit**: `{ inherit user; }` not `user = user;`.
- **Conditionals**: `lib.mkIf` for conditional attr sets; bind local config with `cfg = config.mySystem.<feature>;`.
- **mkOption**: always include `default`, `example`, and `description`.
- **with pkgs**: only inside package lists (`environment.systemPackages = with pkgs; [...]`).
- **mkDefault**: only in `host-defaults.nix` for profile-based defaults.
- **mkForce**: reserved for security overrides only.
- **Comments**: module starts with `# Purpose comment.`; inline comments for non-obvious values; section headers `# === Section Name ===` in large modules.

### Shell scripts

- `#!/usr/bin/env bash`, `set -euo pipefail`, must pass shellcheck.
- Shared logging helpers in `scripts/lib/logging.sh` — source it instead of defining `log_info` locally.
- Sourced library files (`scripts/lib/`) omit `set -euo pipefail` (inherited from caller).

### After adding/removing a `.nix` file

Update the parent `default.nix` imports list, then run `just modules`.

## Anti-Patterns (Forbidden)

| Pattern | Reason |
|---|---|
| PulseAudio + PipeWire | Hard audio stack conflict (validated) |
| Multiple power daemons (TLP + power-profiles-daemon) | Service conflicts (validated) |
| nouveau + NVIDIA proprietary | Driver conflict (validated) |
| DNSCrypt-Proxy + systemd-resolved | DNS conflict (validated) |
| `allowBroken = true` | Unstable packages; find alternative |
| Avahi without explicit `allowInterfaces` | Security risk (validated) |
| Gaming without `hardware.graphics.enable` | Graphics drivers required (validated) |
| `graphene-hardened` kernel | Crashes glycin/bwrap image loaders |
| `auditd` with AppArmor | Kernel panic via `audit_log_subj_ctx` |
| `mkForce` outside security hardening | Use `mkDefault`/`mkOverride` instead |
| Manual formatting | Always use `just format` |
| Channels | Use flake inputs only |

## Code Map (Entry Points)

- **NixOS Entry**: `hosts/<hostname>/configuration.nix` → `nixos/modules/default.nix`.
- **HM Entry**: `home-manager/home.nix` → `home-manager/modules/default.nix`.
- **Identity**: `shared/constants.nix`.
- **Secrets**: `secrets/secrets.yaml` (sops-nix).
- **AI Fleet**: `home-manager/modules/ai-agents/` (10-agent orchestration, embedded bash, `activation.nix`).
- **Observability**: `nixos/modules/prometheus-grafana/` (Loki, Grafana, Prometheus).

## Common Fixes

| Symptom | Fix |
|---|---|
| Missing import error | Add file to parent `default.nix` imports list |
| deadnix warning | Remove unused binding or prefix with `_` |
| statix suggestion | Apply the suggested fix directly |
| Module not found | Check path in `default.nix`, ensure file exists on disk |

## Sub-AGENTS.md Files

Detailed module-level guidance exists at:
`nixos/modules/AGENTS.md`, `nixos/modules/security/AGENTS.md`,
`home-manager/modules/AGENTS.md`, `home-manager/modules/niri/AGENTS.md`,
`home-manager/modules/noctalia/AGENTS.md`, `home-manager/modules/apps/AGENTS.md`,
`home-manager/modules/terminal/AGENTS.md`, `home-manager/modules/ai-agents/AGENTS.md`,
`hosts/AGENTS.md`, `scripts/AGENTS.md`, `dev-shells/AGENTS.md`.
Read these when working in those areas.
