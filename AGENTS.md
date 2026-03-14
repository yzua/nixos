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

- `just modules`: Validate `default.nix` imports (manual maintenance check).
- `just pkgs`: Detect duplicate packages/conflicts.
- `just lint`: Statix + Deadnix + Shellcheck + Markdownlint.
- `just format`: `nixfmt-tree` via `nix fmt`.
- `just check`: `nix flake check --no-build` (Full evaluation).
- `just all`: Validate -> Lint -> Format -> Check -> `nixos` -> `home`.
- `just home`: Home Manager switch (Safe, user-level).
- `just nixos`: NixOS switch (System-level).
- `just report [mode]`: System health report generator.

## Global Conventions

- **mySystem.\* Pattern**: Enable/configure features via custom options.
- **Canonical Layout**: `options.mySystem.X = { enable = ...; }; config = mkIf cfg.enable { ... };`.
- **Standalone HM**: NOT a NixOS module. Separate lifecycle (`just home`).
- **Imports**: Every dir requires `default.nix`. No auto-discovery.
- **Helpers**: Prefix with `_` (e.g., `_lib.nix`). Manual imports only.
- **Strictness**: `allowBroken = false` (enforced). No channels. No cloud dependencies.

## Anti-Patterns (Forbidden)

- `PulseAudio + PipeWire`: Hard audio stack conflict.
- `Power conflicts`: Mixing `TLP`, `power-profiles-daemon`, or `thermald`.
- `Wildcard Avahi`: No `wl*` in `allowInterfaces`.
- `allowBroken = true`: forbidden globally.
- `Manual formatting`: Always use `just format`.
- `Channels`: Use flake inputs only.

## Code Map (Entry Points)

- **NixOS Entry**: `hosts/<hostname>/configuration.nix` -> `nixos/modules/default.nix`.
- **HM Entry**: `home-manager/home.nix` -> `home-manager/modules/default.nix`.
- **Identity**: `shared/constants.nix`.
- **Secrets**: `secrets/secrets.yaml` (sops-nix).
- **AI Fleet**: `home-manager/modules/ai-agents/` (10-agent orchestration, embedded bash, `activation.nix`).
- **Complex Hotspots**: `ai-agents` stack, `agent-inventory.sh`, system observability (`prometheus-grafana/`).
- **Observability**: `nixos/modules/prometheus-grafana/` (Loki, Grafana, Prometheus).
