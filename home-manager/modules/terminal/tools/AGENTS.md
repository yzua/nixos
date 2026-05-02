# Terminal Tools - Agent Guidelines

Operating domain: `/home/yz/System/home-manager/modules/terminal/tools/`.
Primary pattern: One-Module-Per-Tool (OMPT). Unified by shared identity and multi-layered security gates.

---

## Overview

Terminal tools are managed as discrete modules that configure `programs.*` or `home.*` namespaces directly. This isolation ensures that tool-specific logic (aliases, configuration, environment variables) is encapsulated within its own file while remaining part of the unified shell experience.

### One-Module-Per-Tool (OMPT) Pattern

- Each CLI tool has a dedicated `.nix` file (e.g., `bat.nix`, `zoxide.nix`).
- Modules should avoid defining custom options; they must implement settings directly using upstream Home Manager options.
- Shared settings (colors, fonts, identity) must be pulled from `shared/constants.nix`.
- Imports are managed centrally in `default.nix`.

---

## Identity

Identity is centralized in `shared/constants.nix` and consumed by tools to maintain global consistency.

- **User profile**: `constants.user.name`, `constants.user.email`, and `constants.user.signingKey`.
- **Git identity**: Consumed by `git/config.nix`. Note the `includeIf` pattern for `github.com` which swaps the primary email for `constants.user.githubEmail`.
- **Fuzzy finding**: `fzf.nix` uses `constants.color.*` to match the global GruvboxAlt theme.

---

## Security Gates

Terminal tools enforce a "Multi-Layered Git Defense" strategy to prevent secrets leakage and ensure auditability.

### Git Hooks (`git/hooks.nix`)

1. **Pre-commit**:
   - **Secret Scanning**: Runs `gitleaks` on staged changes.
   - **Sanity Checks**: Blocks large files (>5MB) and merge conflict markers. Warns on trailing whitespace (non-blocking).
2. **Commit-msg**:
   - **Conventional Commits**: Enforces the `<type>[scope]: <description>` format.
3. **Post-commit**:
   - **Audit**: Warns immediately if the created commit is unsigned.
4. **Pre-push**:
   - **Final Gate**: Blocks any unsigned commits from leaving the machine. Verify signatures for all commits in the push range.

### Runtime Secret Loading

Tools that require API keys or tokens (for example AI agents) use Zsh wrappers defined in `terminal/zsh/functions.nix`. These wrappers:

- Read secrets from `/run/secrets/` at runtime.
- Never store plain-text secrets in the Nix store or environment variables.

---

## Conventions

- **Aliases**: Define tool-specific aliases within the tool's `.nix` file using `programs.<tool>.shellAliases`.
- **Theming**: Prefer Stylix auto-theming. If manual overrides are required, use `constants.color.*` mappings.
- **Git Aliases**: Git-specific aliases (st, co, br, etc.) live in `git/config.nix`, not Zsh aliases.
- **Scripts**: Complex tool wrappers belong in `terminal/scripts.nix` (Nix-wrapped) or the repo-level `scripts/` directory (standalone Bash).

---

## Validation

Run these commands before committing changes to any terminal tool:

```bash
just modules   # Verify import structure
just pkgs      # Check for duplicate packages and ownership conflicts
just lint      # Check shell scripts and Nix syntax
just format    # Ensure consistent nixfmt-tree formatting
just check     # Full flake evaluation
just home      # Safe user-level deployment
```
