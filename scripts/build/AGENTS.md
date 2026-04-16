# Build Scripts

Build-time quality gates for the NixOS flake configuration repository. Validates module imports, detects package conflicts, enforces commit signing, lints inline shell embedded in Nix.

Parent: `scripts/AGENTS.md`

---

## Files

| File                       | Purpose                                                                                      |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| `modules-check.sh`         | Validates that every `.nix` file in directories with `default.nix` is properly imported      |
| `modules-check-test.sh`    | Unit tests for modules-check.sh                                                              |
| `packages-check.sh`        | Scans for duplicate packages across `home.packages`/`systemPackages` and ownership conflicts |
| `pre-commit-hook.sh`       | Git hook: modules-check, statix/deadnix, format check, flake check                           |
| `pre-push-hook.sh`         | Git hook: blocks unsigned commits (verifies GPG signatures)                                  |
| `shellcheck-nix-inline.sh` | Extracts `writeShellScript` bodies from `.nix` files and lints them                          |

---

## Conventions

- Shebang: `#!/usr/bin/env bash` + `set -euo pipefail`. Sources `../lib/logging.sh`.
- AWK heavy: `modules-check.sh` and `packages-check.sh` write inline AWK scripts to temp files.
- `shellcheck-nix-inline.sh` composes `awk-utils.awk` + `extract-nix-shell.awk` from `../lib/`.
- Temp files use `mktemp -d` with `trap ... EXIT` cleanup.
- Test files: `*-test.sh` suffix alongside the script under test.

---

## Gotchas

- `modules-check.sh` skips `_*.nix` files. Comments with `modules-check: manual-helper` or `imported manually` exclude specific modules.
- `packages-check.sh` skips `_*.nix` files and `*/custom/*` paths, and has a large inline AWK skip-list of non-package `pkgs.*` attributes — new package namespaces may need adding.
- `shellcheck-nix-inline.sh` excludes SC1114, SC1128, SC2239. Blocks with `${lib.` are skipped entirely (Nix-level conditionals).
- `pre-commit-hook.sh` hardcodes an exclude for `./home-manager/modules/terminal/zellij/layouts.nix` in deadnix.
- `pre-push-hook.sh` reads from stdin (git hook protocol: `local_ref local_sha remote_ref remote_sha` per line).

---

## Dependencies

- `../lib/logging.sh`, `../lib/awk-utils.awk`, `../lib/extract-nix-shell.awk`, `../lib/test-helpers.sh`
- External: `awk`, `find`, `sort`, `statix`, `deadnix`, `nix`, `shellcheck`, `rg`, `jq`, `git`
- Referenced by `justfile` (`just modules`, `just pkgs`, `just lint`) and installed as git hooks via `just install-hooks`
