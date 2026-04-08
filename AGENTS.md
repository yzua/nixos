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

**Fastest to slowest (run incrementally until failure, then fix):**

1. `just modules` - Validate `default.nix` imports match disk files (instant)
2. `just pkgs` - Detect duplicate packages and program/module conflicts (fast)
3. `just lint` - Full lint suite: Statix + Deadnix + Shellcheck + Markdownlint (fast)
4. `just dead` - Deadnix only (subset of lint, for dead code detection)
5. `just format` - `nixfmt-tree` via `nix fmt` (fast)
6. `just check` - `nix flake check --no-build` (full evaluation without build, ~10s)

**Running specific checks:**

- Single file: `nix run nixpkgs#statix -- check path/to/file.nix`
- Single script: `nix run nixpkgs#shellcheck path/to/script.sh`
- Dead code: `nix run nixpkgs#deadnix -- --fail path/to/file.nix`
- Inline Bash in Nix: `bash ./scripts/build/shellcheck-nix-inline.sh`

### Apply changes

- `just home`: Home Manager switch (user-level, ~5s)
- `just nixos`: NixOS switch (system-level, ~30s)
- `just all`: Full pipeline: modules → pkgs → lint → format → check → nixos → home

### Other

- `just update`: Update all flake inputs
- `just diff`: Diff current vs previous NixOS generation (`nvd`)
- `just clean`: GC old generations + optimize store
- `just security-audit`: systemd unit hardening + vulnix CVE scan
- `just report [mode]`: System health report generator
- `just sops-view` / `just sops-edit` / `just secrets-add KEY`: Secrets management

### No unit tests

Escalation: `just modules` (fastest) → `just check` (eval) → `just home` (user build) → `just nixos` (system build).

## Global Conventions

- **mySystem.\* Pattern**: Enable/configure features via custom options.
- **Canonical Layout**: `options.mySystem.X = { enable = ...; }; config = mkIf cfg.enable { ... };`.
- **Standalone HM**: NOT a NixOS module. Separate lifecycle (`just home`). HM modules cannot reference NixOS `config.*`.
- **Imports**: Every dir requires `default.nix`. No auto-discovery.
- **Helpers**: Prefix with `_` (e.g., `_lib.nix`). Manual imports only.
- **Strictness**: `allowBroken = false` (enforced). No channels. No cloud dependencies.
- **Constants**: Single source of truth in `shared/constants.nix`.

### Import Patterns

**Every directory must have a `default.nix` with explicit imports:**

```nix
{
  imports = [
    ./gaming.nix      # Steam, Lutris, Wine, MangoHud
    ./nvidia.nix      # NVIDIA driver and CUDA
  ];
}
```

**Helper files (`_*.nix`) are NOT listed in default.nix:**

```nix
let myHelper = import ./_lib.nix { inherit lib; };
in { ... }
```

**After adding/removing a `.nix` file:** Update parent `default.nix` imports, then run `just modules`.

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
- **Imports**: Every directory with `.nix` files must have `default.nix` with inline purpose comments.
- **`_` prefix**: Helper files (`_lib.nix`) are imported manually — NOT listed in `default.nix`.
- **inherit**: Use `{ inherit user; }` not `user = user;`.
- **Conditionals**: `lib.mkIf` for conditional attr sets; bind config with `cfg = config.mySystem.<feature>;`.
- **mkOption**: Always include `default`, `example`, and `description`.
- **with pkgs**: Only inside package lists (`environment.systemPackages = with pkgs; [...]`).
- **mkDefault**: Only in `host-defaults.nix` for profile-based defaults.
- **mkForce**: Reserved for security overrides only.
- **Comments**: Module starts with `# Purpose comment.`; inline comments for non-obvious values.

### Naming Conventions

- **Modules**: lowercase with hyphens (`gaming.nix`, `nvidia.nix`)
- **Options**: camelCase (`enableGamemode`, `hostProfile`)
- **Variables**: camelCase for local bindings (`cfg`, `githubEmailIncludes`)
- **Constants**: camelCase in `constants.nix` (`terminal`, `editor`, `color.bg`)

### Error Handling

- **Assertions**: Use `validation.nix` for cross-module conflicts with format:
  ```nix
  assertions = [{
    assertion = condition;
    message = "Clear explanation and fix";
  }];
  ```
- **Never use `allowBroken = true`**: Find alternative packages or fix upstream
- **Fail fast**: Run `just modules` first to catch import errors

### Shell scripts

- `#!/usr/bin/env bash`, `set -euo pipefail`, must pass shellcheck.
- Shared logging helpers in `scripts/lib/logging.sh` — source it instead of defining `log_info` locally.
- Sourced library files (`scripts/lib/`) omit `set -euo pipefail` (inherited from caller).

## Debugging and Common Fixes

| Symptom                          | Fix                                                                                     |
| -------------------------------- | --------------------------------------------------------------------------------------- |
| Missing import error             | Add file to parent `default.nix` imports list                                           |
| deadnix warning                  | Remove unused binding or prefix with `_`                                                |
| statix suggestion                | Apply the suggested fix directly                                                        |
| Module not found                 | Check path in `default.nix`, ensure file exists on disk                                 |
| Build fails after adding package | Run `just pkgs` to check for duplicates/conflicts                                       |
| Home Manager option not found    | HM modules cannot use NixOS `config.*` — use `constants` or pass via `extraSpecialArgs` |
| Secret not found                 | Run `just sops-view` to verify secret exists in `secrets/secrets.yaml`                  |

### Validation Workflow

1. After creating/editing a module: `just modules`
2. After adding packages: `just pkgs`
3. Before committing: `just lint`
4. After formatting changes: `just format`
5. Before applying: `just check`
6. Safe deployment: `just home` (user-level)
7. Full deployment: `just nixos` (system-level, requires sudo)

## Anti-Patterns (Forbidden)

| Pattern                                   | Reason                                |
| ----------------------------------------- | ------------------------------------- |
| PulseAudio + PipeWire                     | Hard audio stack conflict (validated) |
| Multiple power daemons                    | Service conflicts (validated)         |
| nouveau + NVIDIA proprietary              | Driver conflict (validated)           |
| DNSCrypt-Proxy + systemd-resolved         | DNS conflict (validated)              |
| `allowBroken = true`                      | Unstable packages; find alternative   |
| Avahi without `allowInterfaces`           | Security risk (validated)             |
| Gaming without `hardware.graphics.enable` | Graphics drivers required (validated) |
| `graphene-hardened` kernel                | Crashes glycin/bwrap image loaders    |
| `auditd` with AppArmor                    | Kernel panic via `audit_log_subj_ctx` |
| `mkForce` outside security hardening      | Use `mkDefault`/`mkOverride` instead  |
| Manual formatting                         | Always use `just format`              |
| Channels                                  | Use flake inputs only                 |

## Code Map (Entry Points)

- **NixOS Entry**: `hosts/<hostname>/configuration.nix` → `nixos/modules/default.nix`.
- **HM Entry**: `home-manager/home.nix` → `home-manager/modules/default.nix`.
- **Identity**: `shared/constants.nix`.
- **Secrets**: `secrets/secrets.yaml` (sops-nix).
- **AI Fleet**: `home-manager/modules/ai-agents/` (10-agent orchestration, embedded bash, best-effort skill sync in `activation.nix`).
- **Observability**: `nixos/modules/prometheus-grafana/` (Loki, Grafana, Prometheus).

## Sub-AGENTS.md Files

Detailed module-level guidance exists at:
`nixos/AGENTS.md`, `nixos/modules/AGENTS.md`, `nixos/modules/security/AGENTS.md`,
`nixos/modules/cleanup/AGENTS.md`, `nixos/modules/glance/AGENTS.md`,
`nixos/modules/prometheus-grafana/AGENTS.md`,
`home-manager/AGENTS.md`, `home-manager/modules/AGENTS.md`,
`home-manager/modules/niri/AGENTS.md`, `home-manager/modules/noctalia/AGENTS.md`,
`home-manager/modules/apps/AGENTS.md`, `home-manager/modules/terminal/AGENTS.md`,
`home-manager/modules/terminal/tools/AGENTS.md`, `home-manager/modules/ai-agents/AGENTS.md`,
`home-manager/modules/neovim/AGENTS.md`, `home-manager/modules/languages/AGENTS.md`,
`home-manager/packages/AGENTS.md`,
`hosts/AGENTS.md`, `hosts/laptop/modules/AGENTS.md`,
`scripts/AGENTS.md`, `scripts/system/AGENTS.md`,
`dev-shells/AGENTS.md`.
Read these when working in those areas.
