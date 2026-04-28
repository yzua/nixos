# VS Code Configuration

Declarative VS Code (vscode-fhs) with extensions and writable settings. Unique among HM modules because settings must be mutable — extensions write to `settings.json` at runtime.

---

## Files

| File                      | Purpose                                                              |
| ------------------------- | -------------------------------------------------------------------- |
| `default.nix`             | Import hub: enable, package (`pkgs.vscode-fhs`), `mutableExtensionsDir = true` |
| `extensions.nix`          | Aggregates nixpkgs built-in + marketplace extensions                 |
| `_builtin-extensions.nix` | Extensions from `pkgs.vscode-extensions` (nixpkgs)                   |
| `_marketplace-refs.nix`   | Marketplace extension references (`{ publisher, name, version, sha256 }`) |
| `_settings.nix`           | Settings attrset builder ( Gruvbox theme, formatters, language configs) |
| `activation.nix`          | Writes mutable `settings.json` via HM activation script              |

---

## How Settings Work

Settings go through an activation script, **not** `home.file`:

1. `_settings.nix` produces a Nix attrset.
2. `activation.nix` serializes it to JSON and copies to `~/.config/Code/User/settings.json`.
3. If the existing file is a symlink (from a previous HM generation), it is replaced with a regular file.
4. Extensions can modify settings at runtime; `just home` resets to the declarative baseline.

**Do not** set `enableUpdateCheck` or `enableExtensionUpdateCheck` in `programs.vscode.profiles.default` — HM generates a read-only `settings.json` symlink when those are present, conflicting with the activation script. Equivalent settings are in `_settings.nix` instead (`"update.mode" = "none"`, `"extensions.autoUpdate" = false`).

---

## Adding an Extension

**From nixpkgs** (`_builtin-extensions.nix`):
```nix
pkgs.vscode-extensions.publisher.name
```

**From marketplace** (`_marketplace-refs.nix`):
```nix
{ publisher = "publisher"; name = "name"; version = "x.y.z"; sha256 = "sha256-..."; }
```

After adding, run `just modules && just check && just home`.

---

## Overriding Extension Hashes

When upstream nixpkgs has a stale hash for an extension (e.g., claude-code), `extensions.nix` applies an override via `overrideAttrs`. Follow the existing `claude-code-fix` pattern if needed.

---

## Adding a Setting

Edit `_settings.nix`. The file is a Nix attrset that gets serialized to JSON. Use `constants.font.*`, `constants.color.*`, or `pkgs.*` paths where appropriate.
