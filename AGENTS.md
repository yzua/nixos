# NixOS Configuration - Agent Guidelines

Repository: Flake-based NixOS + Home Manager (hosts: pc, thinkpad)
Stack: nix fmt (nixfmt-tree) | statix + deadnix + shellcheck
Architecture: x86_64-linux, Niri compositor (scrollable tiling Wayland), Gruvbox theming (stylix)

Sub-directory `AGENTS.md` files exist in `nixos/modules/` and `home-manager/modules/` with deeper module-level guidance. Read them when working in those areas.

---

## Commands

### Validation pipeline (run before commits, in this order)
```bash
just modules   # Validate default.nix imports match .nix files on disk (fastest)
just lint      # statix + deadnix + shellcheck
just dead      # deadnix only (subset of lint)
just format    # nixfmt-tree via nix fmt
just check     # nix flake check --no-build (evaluates flake without building)
```

### Apply changes
```bash
just home      # Home Manager switch (safe, user-level) - always run FIRST
just nixos     # NixOS switch (system-level) - run AFTER just home
just all       # Full pipeline: modules -> lint -> format -> check -> nixos -> home
```

### Single-test guidance
No unit-test runner. Escalate: `just modules` (fastest) → `just check` (eval) → `just home` (user build) → `just nixos` (system, last resort).

### Secrets (sops-nix with age encryption)
`just sops-view` (read-only) | `just sops-edit` (edit + auto encrypt/decrypt) | `just secrets-add key value`

---

## Code Style

### Module layout (canonical pattern)
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
    someOption = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "What this option does.";
    };
  };
  config = lib.mkIf config.mySystem.feature.enable {
    # Implementation
  };
}
```

### Formatting (nixfmt-tree)
- Formatter: `nixfmt-tree` (via `nix fmt`). Do NOT manually format; run `just format`.
- Multi-param function args: one-per-line with trailing comma (see module layout above).
- Single-param args stay inline: `{ pkgs, ... }:`
- Lists with comments get one item per line; short lists can be inline.

### Nix conventions
- **inherit**: `{ inherit user; }` not `user = user;`
- **Conditionals**: `lib.mkIf` for conditional attr sets, not `lib.optional`
- **Grouped attrs**: Combine related: `environment = { systemPackages = [...]; sessionVariables = {...}; };`
- **with pkgs**: Use `with pkgs;` only inside package lists (e.g., `environment.systemPackages = with pkgs; [...]`)
- **No channels**: Always reference flake inputs, never channels
- **mkDefault**: Avoid `lib.mkDefault` in regular modules. Use it in `host-defaults.nix` for profile-based defaults that hosts can override
- **allowBroken**: Always `false` (enforced in flake.nix)

### Imports
- Every directory with `.nix` files must have a `default.nix` listing all imports
- Both file (`./file.nix`) and directory (`./subdir`) imports are valid
- Each import gets a short inline comment: `./audio.nix # Audio system (PipeWire)`
- After adding/removing a `.nix` file, update `default.nix` and run `just modules`

### Options and naming
- Custom options live under `mySystem.*` (e.g., `mySystem.gaming.enable`)
- Use `lib.mkEnableOption` for boolean enable flags
- Use `lib.mkOption` with `lib.types.*` for typed options
- Include `default`, `example`, and `description` for all mkOption declarations
- Positive names only: `enableX` not `disableX`
- Standard abbreviations: `pkgs`, `lib`, `cfg`, `config`

### Comments
- Every module starts with a one-line `# Purpose comment.` (period at end)
- Inline comments for non-obvious values: `DiscoverableTimeout = 30; # seconds`
- Section headers use `# === Section Name ===` (in validation/security modules)
- Commented-out code must explain why: `# prometheus removed due to service failures`

### Error handling and validation
- Cross-module conflicts go in `nixos/modules/validation.nix` as assertions
- Assertions use descriptive messages explaining both the conflict and the fix
- Use `lib.optional` for conditional warnings in the `warnings` list
- Document non-default security values inline

### Shell scripts
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Must pass `shellcheck` (via `just lint`)
- Quote all variables: `"$var"`, `"${array[@]}"`
- Use `[[ ... ]]` for conditionals, not `[ ... ]`
- Use `mapfile` for reading arrays from commands
- Error functions: `error_exit "message" code`

---

## Architecture

### Flake structure
```
flake.nix                             # Entry point, makeSystem factory
  hosts/<hostname>/configuration.nix  # Per-host NixOS config
    nixos/modules/default.nix         # ~52 shared system modules
    hosts/<hostname>/modules/         # Host-specific modules
  home-manager/home.nix               # HM entry point (standalone, NOT NixOS module)
    home-manager/modules/default.nix  # User-level modules
    home-manager/packages/            # Package chunks (cli.nix, dev.nix, etc.)
```

### Package strategy
- `pkgs` (nixpkgs unstable) — default for all apps
- `pkgsStable` (nixos-25.11) — critical/stable tools only
- Package chunks receive `{ pkgs, pkgsStable }` and return a list, aggregated via `builtins.concatLists`
- System packages: `environment.systemPackages` in NixOS modules
- User packages: `home.packages` via `home-manager/packages/` chunks

---

## Where to Look

| Task | Location |
|------|----------|
| Add system service/feature | `nixos/modules/*.nix` (use `mySystem.*` option pattern) |
| Add user package | `home-manager/packages/*.nix` (pick domain chunk) |
| Configure program (dotfiles) | `home-manager/modules/` (`programs.*` pattern) |
| Niri compositor settings | `home-manager/modules/niri/` |
| Noctalia Shell (bar, launcher, etc.) | `home-manager/modules/noctalia/` |
| Shell/terminal config | `home-manager/modules/terminal/` |
| Add validation rule | `nixos/modules/validation.nix` |
| Per-host feature toggle | `hosts/<hostname>/configuration.nix` (set `mySystem.*`) |
| Theming/styling | `home-manager/modules/stylix.nix` |
| AI agent configuration | `home-manager/modules/ai-agents/` |
| Shared constants (terminal, editor, font, user identity) | `shared/constants.nix` |
| Utility scripts | `scripts/` (ai, browser, build, sops) |
| Secrets | `secrets/secrets.yaml` (edit with `just sops-edit`) |

---

## Forbidden Patterns

| Pattern | Reason |
|---------|--------|
| PulseAudio + PipeWire simultaneously | Audio stack conflict (validated) |
| Multiple power daemons (TLP + power-profiles-daemon + thermald) | Service conflicts (validated) |
| nouveau + NVIDIA proprietary drivers | Driver conflict (validated) |
| Wildcard WiFi in Avahi (`wl*` in allowInterfaces) | Security risk; use explicit names |
| `allowBroken = true` | Unstable packages; fix or find alternative |
| DNSCrypt-Proxy + systemd-resolved | DNS management conflict (validated) |
| Avahi without explicit `allowInterfaces` | Must list specific interfaces (validated) |
| Gaming without graphics drivers | `hardware.graphics.enable` required (validated) |

"Validated" = enforced by assertions in `nixos/modules/validation.nix`.

---

## Workflow

1. Make changes matching existing patterns in nearby modules
2. Validate: `just modules` → `just lint` → `just format` → `just check`
3. Test: `just home` (safe) → `just nixos` (system)

### Common fixes
- **Missing import**: Add to the parent `default.nix` imports list
- **deadnix warning**: Remove unused binding or prefix with `_`
- **statix suggestion**: Apply the suggested fix directly
- **Module not found**: Check path in `default.nix`, ensure file exists on disk

---

## Notes

- Home Manager is **standalone** (separate `homeConfigurations` output), not a NixOS module. Requires separate `just home` command.
- **`nh`** (Nix Helper) handles all builds. `FLAKE` env var points to `~/System` automatically.
- Overlays go in **NixOS configuration** (not home.nix) because HM uses system pkgs.
- Secrets: `secrets/secrets.yaml` (sops-nix, age-encrypted). Edit with `just sops-edit`. Never commit decrypted secrets, private keys, or `.envrc`.
- Never edit `hardware-configuration.nix` (auto-generated) unless intentional.
- No CI/CD — validation is local via `just` commands.
