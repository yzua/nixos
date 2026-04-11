# Neovim Module

Home Manager Neovim configuration using declarative plugins plus Lua config fragments.
Scope here is Neovim-only behavior; shared editor defaults belong in parent HM modules.

---

## Structure

| Path                   | Purpose                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| `default.nix`          | Main Neovim module: enable flags, plugin set, extra packages, `initLua` assembly               |
| `lua/`                 | Core Lua config (`options.lua`, `keymaps.lua`, `diagnostics.lua`, `treesitter.lua`, `lsp.lua`) |
| `lua/plugins/`         | Plugin-specific Lua setup (cmp, telescope, neo-tree, lint, DAP, etc.)                          |
| `plugins/default.nix`  | Import hub for plugin submodules                                                               |
| `plugins/wakatime.nix` | WakaTime plugin + CLI wiring                                                                   |

---

## Conventions

- Keep plugin declarations in `default.nix` and plugin behavior in `lua/plugins/*.lua`.
- Add new Lua config by appending to `programs.neovim.initLua` in `default.nix`.
- Keep tree-sitter language additions in the single `nvim-treesitter.withPlugins` block.
- Put Neovim runtime tools in `programs.neovim.extraPackages` only when they are Neovim-specific.
- Keep optional plugin modules under `plugins/` and import via `plugins/default.nix`.

---

## Where To Look

- Change keymaps/options/diagnostics/LSP: `lua/*.lua`
- Change plugin behavior: `lua/plugins/*.lua`
- Add/remove plugin packages: `default.nix`
- Add plugin-specific Nix wiring (extra package/env): `plugins/*.nix`

---

## Anti-Patterns

- Mixing plugin Lua configuration directly into `default.nix`.
- Adding a `lua/plugins/*.lua` file without appending it to `initLua`.
- Duplicating plugin setup both in `lua/plugins/` and inline Vimscript snippets.
- Putting non-Neovim toolchain policy here (belongs in `home-manager/modules/programming-languages/`).

---

## Validation

```bash
just modules
just pkgs
just lint
just format
just check
just home
```
