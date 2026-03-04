# Application Configurations

10 app config files + 3 subdirectory modules (VS Code, Brave, LibreWolf). Each app gets one `.nix` file or subdirectory.
No custom options — uses `programs.*`, `services.*`, `home.file`, `xdg.configFile`, `dconf.settings`.

---

## App Map

| File | App | Config Pattern |
|------|-----|----------------|
| `activitywatch.nix` | ActivityWatch | `services.activitywatch` + systemd service (Wayland) |
| `desktop-entries.nix` | Desktop launchers/wrappers | `home.file` + `xdg.desktopEntries` |
| `keepassxc.nix` | KeePassXC | Desktop entry + SSH agent socket |
| `nautilus.nix` | GNOME Files | `dconf.settings` (preferences) |
| `nixcord.nix` | Discord (Vesktop) | `programs.nixcord` (Vencord declarative plugins) |
| `obs.nix` | OBS Studio | `programs.obs-studio` + CUDA + plugins |
| `obsidian.nix` | Obsidian | Desktop entry with Wayland flags |
| `opensnitch-ui.nix` | OpenSnitch | `home.file` for config + autostart |
| `pear-desktop.nix` | Pear Desktop | Theme/plugin baseline files |
| `syncthing.nix` | Syncthing | `services.syncthing` (local file sync) |

## Subdirectory Modules

### `vscode/` (3 files + 1 helper)

| File | Purpose |
|------|---------|
| `default.nix` | Import hub: enable, package (`pkgs.vscode`), `mutableExtensionsDir = true` |
| `extensions.nix` | Extensions from nixpkgs + VS Code marketplace |
| `_settings.nix` | Settings builder (helper, not in `default.nix`) |
| `activation.nix` | Writes mutable `settings.json` via activation script (avoids read-only symlink) |

**Unique pattern**: VS Code settings must be mutable (extensions write to it). `activation.nix` writes `settings.json` at activation time instead of using `home.file` symlink.

### `brave/` (2 files)

| File | Purpose |
|------|---------|
| `default.nix` | Import hub: `programs.chromium` with Brave package |
| `extensions.nix` | 30+ declarative extensions (privacy, dev tools, YouTube) |

### `librewolf/` (1 file)

| File | Purpose |
|------|---------|
| `default.nix` | `programs.librewolf` with declarative policies + profile settings (SOCKS5) |

---

## Adding a New App

1. Create `home-manager/modules/apps/<name>.nix`
2. Add import with comment to `apps/default.nix`
3. Use `programs.*`, `services.*`, or `home.file`/`xdg.configFile`
4. For complex apps with multiple config files: create a subdirectory with `default.nix`
5. Run: `just modules && just lint && just format && just check && just home`
