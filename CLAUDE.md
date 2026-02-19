# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Flake-based NixOS + Home Manager personal system configuration. Hosts: `pc` (desktop). Niri compositor (scrollable tiling Wayland), Gruvbox theming via Stylix, extensive security hardening. Dormant `laptop` host available for future use.

## Commands

### Validation pipeline (run in order before commits)

```bash
just modules   # Validate default.nix imports match .nix files on disk (fastest)
just lint      # statix + deadnix + shellcheck + markdownlint
just dead      # deadnix only (subset of lint)
just format    # nixfmt-tree via nix fmt
just check     # nix flake check --no-build (evaluates without building)
```

### Apply changes

```bash
just home      # Home Manager switch (safe, user-level) — run FIRST
just nixos     # NixOS switch (system-level) — run AFTER just home
just all       # Full pipeline: modules → lint → format → check → nixos → home
```

### Other commands

```bash
just update          # Update all flake inputs
just diff            # Diff current vs previous NixOS generation (nvd)
just clean           # GC old generations + optimize store
just security-audit  # systemd unit hardening + vulnix CVE scan
just install-hooks   # Install pre-commit/pre-push git hooks
just report [mode]   # Generate system health report
```

### No unit tests

Escalate: `just modules` (fastest) → `just check` (eval) → `just home` (user build) → `just nixos` (system build, last resort).

### Secrets

```bash
just sops-view          # View decrypted secrets (read-only)
just sops-edit          # Edit secrets (auto encrypt/decrypt via RAM tmpfs)
just secrets-add KEY    # Add single secret (reads value from stdin)
```

## Architecture

### Flake entry point (`flake.nix`)

- `makeSystem` factory creates `nixosConfigurations` per host
- `homeConfigurations` are **standalone** (separate `just home` command, NOT a NixOS module) — HM modules cannot reference NixOS `config.*` and receive `specialArgs` independently
- `pkgs` = nixpkgs unstable (default), `pkgsStable` = nixos-25.11 (critical tools only — language runtimes, LSP servers, stable CLI tools)
- `constants` from `shared/constants.nix` — single source of truth for terminal, editor, fonts, theme, keyboard, user identity
- Both NixOS and HM receive `specialArgs`: `inputs`, `user`, `pkgsStable`, `constants`, `hostname`
- `nh` (Nix Helper) wraps all builds; `FLAKE` env var points to `~/System` automatically
- **Critical**: niri flake input does NOT follow nixpkgs (`# Do NOT follow nixpkgs — mesa compatibility`) — do not add `inputs.nixpkgs.follows`

### Module hierarchy

```text
flake.nix
  ├─ hosts/<hostname>/configuration.nix     # Per-host: hardware, mySystem.* options
  │    ├─ nixos/modules/default.nix          # ~52 shared NixOS modules
  │    └─ hosts/<hostname>/modules/          # Host-specific hardware modules
  ├─ home-manager/home.nix                   # HM entry point (standalone)
  │    ├─ home-manager/modules/default.nix   # User-level modules
  │    └─ home-manager/packages/default.nix  # 12 domain chunks aggregated via builtins.concatLists
  └─ dev-shells/                             # Per-language dev environments (standalone flakes)
```

### NixOS modules (`nixos/modules/`)

- Custom options live under `mySystem.*` namespace (e.g., `mySystem.gaming.enable`)
- Enable-guard pattern: `config = lib.mkIf config.mySystem.<feature>.enable { ... };`
- `host-defaults.nix` sets `lib.mkDefault` for all `mySystem.*` based on `mySystem.hostProfile` (`"desktop"` | `"laptop"`)
- `validation.nix` — **critical** cross-module conflict assertions (PulseAudio+PipeWire, nouveau+NVIDIA, DNSCrypt+resolved, etc.)
- Sub-directories (`security/`, `cleanup/`, `prometheus-grafana/`) have their own `default.nix` import hubs

### Home Manager modules (`home-manager/modules/`)

- No custom option namespace — directly configure `programs.*`, `services.*`, `home.*`
- Receives `constants` for shared values
- Packages split into 12 domain chunks in `home-manager/packages/`, each with signature `{ pkgs, pkgsStable }: [ ... ]`

### Sub-directory AGENTS.md files

More detailed module-level guidance exists at:

- `nixos/modules/AGENTS.md` — NixOS module categories, option patterns, validation deps
- `home-manager/modules/AGENTS.md` — HM module hierarchy, theming, config patterns
- `home-manager/modules/niri/AGENTS.md` — Niri compositor binds, scripts, Noctalia coupling
- `hosts/AGENTS.md` — Host comparison, adding new hosts

Read these when working in those areas.

### Guides

Specialized reference docs in `guides/`: AI agents, Ghostty, Neovim, Niri, Yazi, Zellij.

## Code Style

### Module layout (canonical)

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

- **Formatter**: `nixfmt-tree` — never manually format, run `just format`
- **Imports**: every directory with `.nix` files must have `default.nix` listing all imports with inline comments
- **`_` prefix files**: Files like `_lib.nix`, `_helpers.nix`, `_mcp-transforms.nix` are helper files imported manually by other modules — NOT listed in `default.nix`. The modules-check script skips them.
- **inherit**: `{ inherit user; }` not `user = user;`
- **Conditionals**: `lib.mkIf` for conditional attr sets
- **with pkgs**: only inside package lists (`environment.systemPackages = with pkgs; [...]`)
- **mkDefault**: only in `host-defaults.nix` for profile-based defaults
- **allowBroken**: always `false` (enforced in flake.nix)
- **No channels**: always reference flake inputs
- **Comments**: module starts with `# Purpose comment.`; inline comments for non-obvious values; section headers use `# === Section Name ===` in large modules
- **Shell scripts**: `#!/usr/bin/env bash`, `set -euo pipefail`, must pass shellcheck. Shared logging helpers live in `scripts/lib/logging.sh` — source it instead of defining `log_info` locally. Sourced library files (`scripts/lib/`) omit `set -euo pipefail` (inherited from caller).

### After adding/removing a `.nix` file

Update the parent `default.nix` imports list, then run `just modules`.

## Forbidden Patterns

| Pattern | Reason |
| ------- | ------ |
| PulseAudio + PipeWire | Audio stack conflict (validated) |
| Multiple power daemons | Service conflicts (validated) |
| nouveau + NVIDIA proprietary | Driver conflict (validated) |
| DNSCrypt-Proxy + systemd-resolved | DNS conflict (validated) |
| `allowBroken = true` | Unstable packages; find alternative |
| Avahi without explicit `allowInterfaces` | Security risk (validated) |
| Gaming without `hardware.graphics.enable` | Graphics drivers required (validated) |

"Validated" = enforced by assertions in `nixos/modules/validation.nix`.

## Where to Look

| Task | Location |
| ---- | -------- |
| Add system service/feature | `nixos/modules/*.nix` (use `mySystem.*` option pattern) |
| Add user package | `home-manager/packages/*.nix` (pick domain chunk) |
| Configure program (dotfiles) | `home-manager/modules/` (`programs.*` pattern) |
| Niri compositor settings | `home-manager/modules/niri/` |
| Noctalia Shell (bar, launcher) | `home-manager/modules/noctalia/` |
| AI agent configuration | `home-manager/modules/ai-agents/` |
| Per-host feature toggle | `hosts/<hostname>/configuration.nix` (set `mySystem.*`) |
| Cross-module validation | `nixos/modules/validation.nix` |
| Profile defaults | `nixos/modules/host-defaults.nix` |
| Shared constants | `shared/constants.nix` |
| Secrets | `secrets/secrets.yaml` (edit with `just sops-edit`) |
| Utility scripts | `scripts/` (ai, browser, build, lib, sops, system) |
| Dev environments | `dev-shells/<lang>/flake.nix` |
