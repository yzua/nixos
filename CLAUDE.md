# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal NixOS + standalone Home Manager configuration repo. Flake-based, single user (`yz`), currently only `desktop` host is active (`hosts/_inventory.nix`).

## Commands

```bash
just modules          # Validate default.nix import structure
just pkgs             # Check for duplicate packages and program/module ownership conflicts
just lint             # statix + deadnix + shellcheck + inline Nix shell scripts + markdownlint (parallel)
just format           # nix fmt (nixfmt-tree via flake formatter)
just test             # Run all shell test suites (*-test.sh files)
just check            # nix flake check --no-build path:. (eval-only)
just home             # home-manager switch for yz@desktop
just nixos            # nh os switch for desktop
just all              # Full pipeline: modules/pkgs/lint parallel -> format -> test -> check -> nixos -> home
just install-hooks    # Install repo-local pre-commit/pre-push hooks
just update           # nix flake update (with pre/post check)
just upgrade          # update -> nixos -> home -> security-audit
just clean            # nh clean all --keep 1 + HM expire + store optimise
just diff             # NVD diff between current and previous NixOS generation
just security-audit   # systemd-analyze security + vulnix
just sops-edit        # Edit sops-encrypted secrets
just sops-view        # View sops-encrypted secrets
just secrets-add KEY  # Add a new secret key
```

No traditional unit-test suite — validation is import/lint/eval/apply. Shell tests live beside their scripts as `*-test.sh`. The root dev shell (`nix develop`) only provides `statix`, `deadnix`, `shellcheck`, and `nixfmt-tree`; `home-manager` and `nh` come from the host system.

## Architecture

### Entrypoints and Data Flow

- **`flake.nix`**: Generates `nixosConfigurations` and `homeConfigurations` from `hosts/_inventory.nix`. Passes `specialArgs` / `extraSpecialArgs` into both worlds.
- **`hosts/<hostname>/configuration.nix`**: NixOS entrypoint. Imports `../../nixos-modules` and host-specific `./modules`.
- **`home-manager/home.nix`**: HM entrypoint. Imports `./modules` (config) and `./packages` (package lists).

### SpecialArgs (how shared values flow in)

**NixOS modules** receive: `inputs`, `stateVersion`, `hostname`, `user`, `pkgsStable`, `pkgConfig`, `constants`, `systemdHelpers`, `optionHelpers`.

**Home Manager modules** receive: `inputs`, `homeStateVersion`, `user`, `pkgsStable`, `constants`, `optionHelpers`, `secretLoader`, `hmSystemdHelpers`, `hostname`.

HM is standalone — it cannot access NixOS `config.*`. Shared values arrive only through `extraSpecialArgs`.

### Key Shared Files

- `shared/constants.nix` — single source of truth for user identity, terminal, editor, fonts, theme, colors, ports, paths, proxies, keyboard layout
- `shared/_option-helpers.nix` — typed option constructors for `mySystem.*` toggles
- `home-manager/_helpers/_secret-loader.nix` — reads from `/run/secrets/*` (sops-nix)
- `home-manager/_helpers/_systemd-helpers.nix` — systemd unit helpers for HM services
- `home-manager/_helpers/_egl-wrap.nix` — Mesa EGL vendor override wrapper for GUI binaries

### NixOS Modules (`nixos-modules/`)

Feature modules use the `mySystem.*` namespace pattern:

1. Define option: `options.mySystem.<name>.enable`
2. Guard config: `lib.mkIf config.mySystem.<name>.enable`
3. Apply settings inside the guard

`host-defaults.nix` sets profile defaults (`desktop`/`laptop`) based on `mySystem.hostProfile`. Cross-module assertions go in `validation.nix`, not in feature modules.

Sub-module directories (`security/`, `cleanup/`, `glance/`, `prometheus-grafana/`, `helpers/`, `nix-ld/`, `system-report/`) have their own `default.nix` hubs.

### Home Manager (`home-manager/`)

- `modules/` — program/service configs (behavioral)
- `packages/` — domain-chunked `home.packages` lists
- Only custom HM option namespace: `programs.aiAgents.*` in `modules/ai-agents/`
- Helper files prefixed `_` are manual imports, not import-hub entries

### Scripts (`scripts/`)

Bash scripts in `ai/`, `apps/`, `build/`, `hardware/`, `sops/`, `system/`. Shared libraries in `lib/` (`logging.sh`, `test-helpers.sh`, `require.sh`, `error-patterns.sh`, `log-dirs.sh`, `fzf-theme.sh`, `extract-nix-packages.awk`, `extract-nix-shell.awk`, `awk-utils.awk`). Directly-executable scripts must use `#!/usr/bin/env bash` + `set -euo pipefail` (library/sourced scripts omit `set`). Scripts referenced from Nix are wrapped via `pkgs.writeShellScriptBin` (primary) or `pkgs.writeShellApplication`.

## Repo-Enforced Rules

- Every module directory needs a `default.nix` import hub. `modules-check.sh` validates this.
- Helper files are `_*.nix`, imported manually. If `default.nix` references one, add a `# modules-check: manual-helper` or `# imported manually` comment on that line.
- `niri` must **not** follow `nixpkgs` in `flake.nix` (mesa compatibility).
- `homeStateVersion` is hardcoded to `"25.11"` in `flake.nix`, separate from per-host NixOS `stateVersion` in `_inventory.nix`.
- Secrets use sops — never plaintext. Access via `just sops-edit`, `just sops-view`, or `just secrets-add KEY`.
- Secret-backed features read `/run/secrets/*`; run `just nixos` before `just home` if those files are missing.
- Pre-commit hook runs: modules-check -> statix -> deadnix -> format check -> flake check (no pkgs/shellcheck/markdownlint). Deadnix excludes `home-manager/modules/terminal/zellij/layouts.nix` — do not "fix" dead code there (note: `just lint` does not exclude this file).
- Pre-push hook enforces GPG-signed commits.

## Scoped AGENTS.md Files

Area-specific guidance exists in nested `AGENTS.md` files under `hosts/`, `nixos-modules/`, `home-manager/`, `scripts/`, `dev-shells/`, `shared/`, and `themes/`. Read the nearest one before editing in that area.
