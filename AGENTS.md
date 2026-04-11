# System Repo Notes

- Personal flake-based NixOS + standalone Home Manager config. `desktop` is the only active host; `laptop` exists in `hosts/_inventory.nix` but `enabled = false`.
- `flake.nix` generates both `nixosConfigurations` and `homeConfigurations` from `hosts/_inventory.nix`. If a host is not enabled there, it is effectively out of scope.
- `just home` and `just nixos` are hardcoded to `yz@desktop` and `desktop`. They are not generic wrappers for arbitrary hosts.

## Validate First

- Fastest focused checks: `just modules`, `just pkgs`, `just lint`, `just format`, `just check`.
- `just all` is the real pipeline, not a shorthand guess: `modules`, `pkgs`, and `lint` run in parallel first; then `format`, `check`, `nixos`, and `home` run sequentially.
- Safe apply order while iterating is usually `just home` before `just nixos`, but `just all` intentionally applies `nixos` before `home` because that is how the `justfile` is written.
- There are no normal unit-test suites at repo root. Verification is eval/lint/build oriented.

## Repo Rules That Are Enforced

- Every directory with Nix modules must have a `default.nix` import hub. `just modules` walks all of them and fails on missing imports or broken directory imports.
- Helper files stay prefixed `_*.nix` and are manually imported, not added to import hubs.
- If a non-module helper must be mentioned inside `default.nix`, annotate it with a comment like `modules-check: manual-helper ...`; `scripts/build/modules-check.sh` looks for that exact escape hatch.
- `just pkgs` checks more than duplicate packages: it also flags packages installed both explicitly and via `programs.<name>` or `services.<name>`. Give each package a single owner.

## Architecture Shortcuts

- System entrypoint: `hosts/<host>/configuration.nix` importing `../../nixos-modules`.
- Home entrypoint: `home-manager/home.nix` importing `./modules` and `./packages`.
- Home Manager is standalone here, not embedded as a NixOS module. HM code cannot rely on NixOS `config.*`; shared values come through flake `extraSpecialArgs` like `constants`, `hostname`, and `pkgsStable`.
- Shared system features live under `mySystem.*`; host configs set `mySystem.hostProfile` and then override only deltas.
- `nixos-modules/validation.nix` is the place for cross-module conflicts. Do not scatter those assertions into feature modules.

## Paths That Matter

- `shared/constants.nix`: single source of truth for identity, terminal, editor, fonts, and shared defaults.
- `nixos-modules/default.nix`: real system module map.
- `home-manager/modules/default.nix`: real HM module map.
- `home-manager/packages/default.nix`: package chunk ownership for `home.packages`.
- `scripts/build/modules-check.sh` and `scripts/build/packages-check.sh`: source of truth for what repo validation actually enforces.

## Operational Gotchas

- `niri` intentionally does not follow `nixpkgs` in `flake.nix`; do not "clean that up".
- Root dev shell is minimal: formatter/lint tools only (`statix`, `deadnix`, `shellcheck`, `nixfmt-tree`). Do not assume it provides the full deployment toolchain.
- Repo-local hooks are optional and installed by `just install-hooks`; they chain after Home Manager-managed global hooks.
- Secrets are managed through `sops` helpers (`just sops-view`, `just sops-edit`, `just secrets-add KEY`). Never write secrets into Nix files.

## Area Guides

- Read the nearest nested `AGENTS.md` before changing code under `nixos-modules/`, `home-manager/`, `scripts/`, `hosts/`, or `dev-shells/`.
- Especially relevant sub-guides: `nixos-modules/AGENTS.md`, `home-manager/modules/AGENTS.md`, `home-manager/modules/ai-agents/AGENTS.md`, `scripts/AGENTS.md`, `hosts/AGENTS.md`, `dev-shells/AGENTS.md`.
