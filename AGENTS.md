# System Repo Notes

- Personal flake-based NixOS + standalone Home Manager repo.
- `flake.nix` generates `nixosConfigurations` and `homeConfigurations` from `hosts/_inventory.nix`; only `desktop` is enabled today, so `just check` / `just all` do not validate dormant `laptop` paths.
- `just home` and `just nixos` are hardcoded to `yz@desktop` and `desktop`. For any other host, use explicit `home-manager switch --flake ...#user@host` / `nh os switch 'path:.' --hostname <host>` commands.

## Validate with repo commands

- Start with `just modules`, `just pkgs`, `just lint`, and `just check`.
- `just all` is the full desktop pipeline: `modules`, `pkgs`, and `lint` in parallel, then `format -> check -> nixos -> home`.
- `just check` is eval-only: `nix flake check --no-build path:.`. It does not replace `just home` or `just nixos`.
- `just format` rewrites `.nix` files via `nix fmt`; the hook's check-only equivalent is `nix fmt -- --fail-on-change --no-cache .`.
- There is no normal unit-test suite at repo root; validation here is mostly import/lint/eval/apply.
- The root dev shell only provides `statix`, `deadnix`, `shellcheck`, and `nixfmt-tree`; `home-manager` / `nh` come from the host system.

## Repo-enforced rules

- Every module directory needs a `default.nix` import hub. `scripts/build/modules-check.sh` walks every `default.nix`, flags unimported local `*.nix`, and rejects directory imports without their own `default.nix`.
- Helper files stay `_*.nix` and are imported manually. If a `default.nix` must mention one, add a `# modules-check: manual-helper ...` or `# imported manually ...` comment on that line.
- `just pkgs` scans `home-manager/packages`, `home-manager/modules`, `nixos-modules`, and `hosts` for duplicate packages plus `programs.*` / `services.*` ownership conflicts.
- `just install-hooks` installs repo-local hooks after Home Manager-managed global hooks. Pre-commit runs `modules-check -> statix -> deadnix -> format check -> flake check`; it does **not** run `just pkgs`, `shellcheck`, or `markdownlint`. Pre-push rejects unsigned commits.

## Architecture shortcuts

- System entrypoint: `hosts/<host>/configuration.nix`, which imports `../../nixos-modules`.
- Home Manager entrypoint: `home-manager/home.nix`, which imports `./modules` and `./packages`.
- Home Manager is standalone here, not a NixOS module: HM code cannot rely on NixOS `config.*`; shared values arrive through flake `extraSpecialArgs` such as `constants`, `hostname`, and `pkgsStable`.
- Shared identity, terminal, editor, theme, and service defaults live in `shared/constants.nix`.
- System feature toggles live under `mySystem.*`; set `mySystem.hostProfile` first and override deltas. Put cross-module assertions in `nixos-modules/validation.nix`, not feature modules.

## Gotchas

- `niri` intentionally does **not** follow `nixpkgs` in `flake.nix`; do not “simplify” that.
- Secret-backed features read `/run/secrets/*`; if those files are missing, run `just nixos` before `just home`.
- Secrets belong in `sops`; use `just sops-view`, `just sops-edit`, or `just secrets-add KEY`, never plaintext Nix.

## Scoped guides

- Read the nearest nested `AGENTS.md` before editing `nixos-modules/`, `home-manager/`, `scripts/`, `hosts/`, `dev-shells/`, or `themes/`.
