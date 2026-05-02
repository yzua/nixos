# Home Manager Package Chunks

Package declarations for `home.packages`. This directory is chunked by domain and imported via `default.nix`.

---

## Overview

- Each chunk is a Home Manager module that sets `home.packages = [ ... ];`
- `default.nix` is the import hub and controls inclusion order
- `custom/` holds local derivations not available as plain `pkgs.<name>`

## Structure

- `default.nix` — Import hub for all chunks
- `applications.nix` — Desktop apps + GTK/theme package extras
- `cli.nix` — CLI toolchain
- `development.nix` — Dev tooling and databases
- `lsp-servers.nix` — Language servers for editors (shared across languages)
- `networking.nix` — Network analysis and diagnostics
- `niri.nix` — Niri/Wayland-related packages
- `privacy.nix` — Privacy/security user tools
- `system-monitoring.nix` — Observability user tools
- `utilities.nix` — General utility packages
- `custom/` — Import hub + local/custom package definitions (`beads`, `chrome-devtools`, `cursor`, `kiro`, `prayer`)
- `_egl-wrap.nix` — Helper at `../_helpers/_egl-wrap.nix`, imported manually by chunks; not imported by `default.nix`

---

## Conventions

- Keep one package domain per file; add packages to an existing domain chunk first
- Use top-level module args with trailing comma style:

```nix
{
  pkgs,
  pkgsStable,
  ...
}:
```

- Prefer `pkgs` by default; use `pkgsStable` only for intentionally pinned tools
- For helper files prefixed with `_`, import directly from the consuming chunk
- For custom binaries, use explicit source + hash and set `meta.mainProgram`

---

## Where To Look

- Add regular package: existing domain chunk in this directory
- Add custom/local package: `custom/*.nix`
- Add helper logic shared by chunks: `../_helpers/_*.nix` (imported manually)
- Wire new chunk into aggregation: `default.nix`

---

## Anti-Patterns

- Creating a new chunk for a single package when an existing domain fits
- Using `pkgsStable` broadly instead of selectively for stability needs
- Duplicating the same package in multiple chunks
- Importing helper `_*.nix` files from `default.nix`
- Putting system-level packages here (system packages belong in NixOS modules)

---

## Validation

After edits in this directory:

```bash
just modules
just pkgs
just lint
just format
just check
just home
```
