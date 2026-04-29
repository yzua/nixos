# NixOS Modules - Agent Guidance

## OVERVIEW

This directory contains shared NixOS system modules. These files define the core behavior and optional features for every host in the fleet. All modules are aggregated in a central hub. This setup ensures that every machine follows the same rules while allowing for specific host overrides.

## STRUCTURE

The module system follows a strict layout:

- **default.nix**: The central hub. It imports every module and directory in this path.
- **host-defaults.nix**: Sets profile defaults. It handles common settings for desktops and laptops.
- **host-info.nix**: Hostname and state version management from flake arguments.
- **validation.nix**: The safety layer. It uses assertions to stop conflicting services.
- **Feature Modules**: Single files like `gaming.nix`, `nvidia.nix`, or `backup.nix` that manage specific subsystems.
- **Sub-module Directories**: Paths like `security/`, `cleanup/`, `glance/`, `prometheus-grafana/` that have their own internal hubs.
- **helpers/**: Internal helpers (`_systemd-helpers.nix`, `_service-urls.nix`). Not in the hub; import manually.
- **`../shared/`**: Cross-cutting helpers (`constants.nix` for identity/defaults, `_option-helpers.nix` for typed option constructors, `_secret-loader.nix` for secret loading, `_hm-systemd-helpers.nix` for HM systemd unit helpers). Lives at repo root, not inside this directory. Import via `../shared/`.

## WHERE TO LOOK

- **Toggle a feature**: Open the specific module file and look for `mySystem.*` options.
- **Add a safety rule**: Edit `validation.nix`. Add your rule to the `assertions` list.
- **Change laptop defaults**: Find the laptop section in `host-defaults.nix`.
- **Find security values**: Go to `security/AGENTS.md` for hardening details.

## CONVENTIONS

### The mySystem.\* Pattern

We use the `mySystem` namespace for all custom toggles. This makes it easy to see which features are active. Most modules use this three step pattern:

1. **Define the option**: Create an `enable` toggle under `options.mySystem.<name>`.
2. **Guard the config**: Wrap everything in `lib.mkIf config.mySystem.<name>.enable`.
3. **Apply settings**: Use standard NixOS options inside that guard.

### Import Hub Rules

The `default.nix` file is the master registry. Every new module must be listed there. Add a comment next to each import to explain what the file does.

### Helper Files

Files that start with an underscore are internal helpers. For example, `cleanup/_lib.nix` exposes timer constructors. These are not added to the central hub. You must import them manually in the files that need their logic.

## ANTI-PATTERNS

- **Host-specific hardware**: Don't put policy for a single machine here. Keep those files in the `hosts/` path.
- **Scattered checks**: Avoid putting cross-module assertions inside feature files. Use `validation.nix` instead.
- **Hidden enablement**: Don't turn on services without a `mySystem` toggle. Mandatory features are the only exception.

---

## Adding a New System Feature

Follow these steps to add a new capability:

1. **Create the file**: Make a new module like `nixos-modules/new-feature.nix`.
2. **Add options**: Define a `mySystem.new-feature.enable` toggle.
3. **Update the hub**: Register the file in `nixos-modules/default.nix`.
4. **Define defaults**: Update `host-defaults.nix` if the feature should be on by default.
5. **Enforce safety**: Add assertions to `validation.nix` if there are conflicts with other modules.
6. **Verify work**: Run `just check` to make sure the evaluation passes.

## Validation and Conflicts

`validation.nix` acts as the system immune system. It blocks bad combinations that could break the build or cause runtime errors. It handles things like:

- **Power conflicts**: Stopping TLP and Power Profiles Daemon from fighting.
- **Audio battles**: Making sure PipeWire and PulseAudio don't overlap.
- **Driver issues**: Ensuring proprietary and open-source GPU drivers stay separate.
- **Safety checks**: Requiring the firewall and AppArmor to be active at all times.

## Profile Defaults

We use `host-defaults.nix` to reduce boilerplate. Setting `mySystem.hostProfile` to `desktop` or `laptop` turns on a pre-selected set of features. This allows host configurations to stay small. You only need to write overrides for the things that differ from the profile.

## Feature Namespaces

Modules are grouped into these namespaces:

- **Core**: Boot, nix, users, timezone, i18n, environment, kernel-tuning, host-info, system-services, resource limits.
- **Hardware**: GPU, audio, bluetooth, input, power (UPower), firmware updates.
- **Desktop**: Niri, greetd, xserver, portals, file manager (Nautilus).
- **Networking**: NetworkManager, encrypted DNS, VPNs, Tor, I2P, mesh networks.
- **Security**: Hardening, application firewall, secure boot, secrets.
- **Apps**: Gaming, flatpak, printing, android, web RE tools, browser deps, KDE Connect, remote access.
- **Virtualization**: Docker, VMs, android containers, dynamic linker.
- **Notifications**: Alertmanager → ntfy.sh push bridge.
- **Observability**: Metrics, dashboards, logs (Loki + Alloy shipper), health reports, alerts.
- **Boot optimization**: Deferred service startup.
- **Maintenance**: Cleanup timers, backups, Nix Helper (`nh`).
