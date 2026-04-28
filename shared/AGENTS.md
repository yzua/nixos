# Shared Helpers

Cross-cutting Nix expressions imported by both NixOS and Home Manager modules via relative path. Not a Nix module — plain attrsets and functions passed through flake `specialArgs`.

---

## Files

| File                    | Purpose                                                                        | Consumers                              |
| ----------------------- | ------------------------------------------------------------------------------ | -------------------------------------- |
| `constants.nix`         | Single source of truth: user identity, terminal/editor, fonts, theme, colors, keyboard, proxies, service ports, paths, system arch | All NixOS and HM modules via `constants` |
| `_option-helpers.nix`   | Typed option constructors (`mkBoolOption`, `mkStrOption`, etc.)                | NixOS modules via `optionHelpers`      |
| `_alias-helpers.nix`    | Applies `shellAliases` to both zsh and bash                                    | `terminal/zsh/aliases.nix`             |
| `_secret-loader.nix`    | `_load_secret` bash function (reads from `/run/secrets/`)                      | `terminal/zsh/functions.nix`, ai-agents launchers |
| `_hm-systemd-helpers.nix` | Home Manager systemd timer constructors (`mkPersistentTimer`, `mkWeeklyTimer`) | HM modules that define systemd timers  |

---

## Import Pattern

Import via relative path, passing required arguments:

```nix
# From nixos-modules/
optionHelpers = import ../shared/_option-helpers.nix { inherit lib; };

# From home-manager/modules/
constants = constants; # already in extraSpecialArgs
aliasHelpers = import ../../../shared/_alias-helpers.nix { inherit shellAliases; };
```

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
- `services` — external API endpoints and model aliases

---

## Gotchas

- Do not add logic or side effects to `constants.nix` — it must remain a pure attrset.
- `_option-helpers.nix` requires `{ lib }` as its argument; it is not a module.
- `_alias-helpers.nix` takes `{ shellAliases }` and returns `programs` attrset for both zsh and bash.
