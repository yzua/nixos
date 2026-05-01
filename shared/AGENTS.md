# Shared Helpers

Nix expressions imported by both NixOS and Home Manager modules via flake `specialArgs`/`extraSpecialArgs`. Not Nix modules — plain attrsets and functions.

HM-only helpers have been moved to `home-manager/_helpers/` to keep this directory focused on truly cross-cutting code.

---

## Files

| File                  | Purpose                                                                                                                            | Consumers                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `constants.nix`       | Single source of truth: user identity, terminal/editor, fonts, theme, colors, keyboard, proxies, service ports, paths, system arch | All NixOS and HM modules via `constants`                    |
| `_option-helpers.nix` | Typed option constructors (`mkBoolOption`, `mkStrOption`, etc.)                                                                    | NixOS modules + `ai-agents/options.nix` via `optionHelpers` |

---

## Import Pattern

The flake pre-imports all shared files and passes them as `specialArgs`/`extraSpecialArgs`, so most modules receive them as function arguments rather than importing directly.

---

## Constants Reference

`constants.nix` is the most-imported file. Key namespaces:

- `user` — handle, name, email, signingKey (drives git identity, GPG, GitHub config)
- `terminal` / `editor` — default app names and Wayland app-ids
- `font` — mono font, nerd font variant, sizes
- `color` — full Gruvbox palette (bright + dim variants) for apps outside Stylix
- `keyboard` — XKB layout, variant, options
- `ports` — all localhost service port assignments
- `paths` — HOME-relative paths for scripts, logs, SDK, sops keys
- `proxies` — Mullvad SOCKS5 endpoints per browser profile

---

## Gotchas

- Do not add logic or side effects to `constants.nix` — it must remain a pure attrset.
- `_option-helpers.nix` requires `{ lib }` as its argument; it is not a module.
