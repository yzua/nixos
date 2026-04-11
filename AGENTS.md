# System Repo Notes

- Personal flake-based NixOS + standalone Home Manager config.
- `flake.nix` generates both `nixosConfigurations` and `homeConfigurations` from `hosts/_inventory.nix`; today only `desktop` is enabled, so `laptop` is usually out of scope.
- `just home` and `just nixos` are hardcoded to `yz@desktop` and `desktop`; they are not generic host wrappers.

## Validate With Repo Commands

- Fast checks: `just modules`, `just pkgs`, `just lint`, `just format`, `just check`.
- `just check` is eval-only: `nix flake check --no-build path:.`. It does not replace `just home` or `just nixos`.
- `just all` is the real full pipeline: `modules`, `pkgs`, and `lint` in parallel, then `format -> check -> nixos -> home`.
- There is no normal unit-test suite at repo root; verification here is mostly import/lint/eval/apply.

## Rules The Repo Enforces

- Every module directory needs a `default.nix` import hub. `scripts/build/modules-check.sh` walks all `default.nix` files and fails on missing local imports or broken directory imports.
- Helper files stay prefixed `_*.nix` and are imported manually, not added to import hubs.
- If `default.nix` must mention a non-module helper, annotate it with `modules-check: manual-helper ...`; the modules check looks for that exact escape hatch.
- `just pkgs` also checks ownership conflicts: a package cannot be installed explicitly and also enabled via `programs.<name>` or `services.<name>`.

## Architecture Shortcuts

- System entrypoint: `hosts/<host>/configuration.nix`, which imports `../../nixos-modules`.
- Home Manager entrypoint: `home-manager/home.nix`, which imports `./modules` and `./packages`.
- Home Manager is standalone here, not a NixOS module. HM code cannot rely on NixOS `config.*`; shared values arrive through flake `extraSpecialArgs` like `constants`, `hostname`, and `pkgsStable`.
- System feature toggles live under `mySystem.*`; hosts set `mySystem.hostProfile` first and override only deltas.
- Put cross-module assertions in `nixos-modules/validation.nix`, not in feature modules.

## Operational Gotchas

- `niri` intentionally does **not** follow `nixpkgs` in `flake.nix`; do not “simplify” that.
- Root dev shell only provides formatter/lint tools (`statix`, `deadnix`, `shellcheck`, `nixfmt-tree`).
- `just install-hooks` installs repo-local hooks after Home Manager-managed global hooks. The pre-commit hook runs `modules-check`, then `statix` + `deadnix`, then `nix fmt -- --fail-on-change --no-cache .`, then `nix flake check --no-build path:.`; it does **not** run `just pkgs`, `shellcheck`, or `markdownlint`.
- Secrets belong in `sops`, via `just sops-view`, `just sops-edit`, and `just secrets-add KEY`; never write secrets into Nix files.

## High-Value Paths

- `shared/constants.nix`: identity, terminal, editor, fonts, theme, color palette, keyboard layout, proxy endpoints, service URLs.
- `nixos-modules/default.nix`: system module registry.
- `home-manager/modules/default.nix`: HM module registry.
- `home-manager/packages/default.nix`: `home.packages` ownership.
- `scripts/build/modules-check.sh` and `scripts/build/packages-check.sh`: executable source of truth for repo validation.

## Area Guides

- Read the nearest nested `AGENTS.md` before editing `nixos-modules/`, `home-manager/`, `scripts/`, `hosts/`, or `dev-shells/`.
- Start with: `nixos-modules/AGENTS.md`, `home-manager/modules/AGENTS.md`, `home-manager/modules/ai-agents/AGENTS.md`, `scripts/AGENTS.md`, `hosts/AGENTS.md`, `dev-shells/AGENTS.md`.
