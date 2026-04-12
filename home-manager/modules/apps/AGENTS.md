# Application Configurations

11 root app config files + 3 subdirectory modules (VS Code, Brave, LibreWolf). Each app gets one `.nix` file or subdirectory.
No custom options — uses `programs.*`, `services.*`, `home.file`, `xdg.configFile`, `dconf.settings`.

---

## App Map

| File                    | App                        | Config Pattern                                     |
| ----------------------- | -------------------------- | -------------------------------------------------- |
| `activitywatch.nix`     | ActivityWatch              | `services.activitywatch` (Wayland watcher setup)   |
| `chromium.nix`          | Chromium                   | Launch wrapper with Wayland crash workaround       |
| `desktop-entries.nix`   | Desktop launchers/wrappers | `home.file` + `xdg.desktopEntries`                 |
| `keepassxc.nix`         | KeePassXC                  | Desktop entry                                      |
| `nautilus.nix`          | GNOME Files                | `dconf.settings` (preferences)                     |
| `nixcord.nix`           | Discord (Vesktop)          | `programs.nixcord` (Vencord declarative plugins)   |
| `obs.nix`               | OBS Studio                 | `programs.obs-studio` + CUDA + plugins             |
| `obsidian.nix`          | Obsidian                   | Desktop entry + default vault registration         |
| `opensnitch-ui.nix`     | OpenSnitch                 | `services.opensnitch-ui` enablement                |
| `syncthing.nix`         | Syncthing                  | `services.syncthing` (local file sync)             |
| `metadata-scrubber.nix` | Metadata scrubber          | inotifywait watcher + weekly full scrub via `mat2` |

## Subdirectory Modules

### `vscode/` (3 files + 3 helpers)

| File                      | Purpose                                                                         |
| ------------------------- | ------------------------------------------------------------------------------- |
| `default.nix`             | Import hub: enable, package (`pkgs.vscode-fhs`), `mutableExtensionsDir = true`  |
| `extensions.nix`          | Extensions from nixpkgs + VS Code marketplace                                   |
| `_settings.nix`           | Settings builder (helper, not in `default.nix`)                                 |
| `_builtin-extensions.nix` | Built-in extension list (helper)                                                |
| `_marketplace-refs.nix`   | Marketplace extension references (helper)                                       |
| `activation.nix`          | Writes mutable `settings.json` via activation script (avoids read-only symlink) |

**Unique pattern**: VS Code settings must be mutable (extensions write to it). `activation.nix` writes `settings.json` at activation time instead of using `home.file` symlink.

### `brave/` (2 files)

| File             | Purpose                                                                                 |
| ---------------- | --------------------------------------------------------------------------------------- |
| `default.nix`    | Import hub: `programs.brave` with Brave package                                         |
| `extensions.nix` | Declarative extensions grouped by GitHub, privacy/security, web dev, and YouTube/social |

### `librewolf/` (3 files)

| File              | Purpose                                                                    |
| ----------------- | -------------------------------------------------------------------------- |
| `default.nix`     | `programs.librewolf` with declarative policies + profile settings (SOCKS5) |
| `_profiles.nix`   | Single source of truth for 6 browser profiles (name, proxy, homepage)      |
| `_extensions.nix` | Extension declarations (not a module, imported by default.nix)             |

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

---

## Adding a New App

1. Create `home-manager/modules/apps/<name>.nix`
2. Add import with comment to `default.nix`
3. Use `programs.*`, `services.*`, or `home.file`/`xdg.configFile`
4. For complex apps with multiple config files: create a subdirectory with `default.nix`
5. Run: `just modules && just lint && just format && just check && just home`
