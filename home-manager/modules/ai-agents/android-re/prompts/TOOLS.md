# Android RE Tools

## Installed On This Machine

### Emulator and device control

- `adb`
- `emulator`
- `avdmanager`
- `sdkmanager`
- Android Studio

### Dynamic analysis

- `frida`
- `frida-ps`
- rooted AVD with unattended `su 0 ...`
- staged ARM64 Frida server for future host-compatible ARM workflows

### Proxy and network

- `mitmproxy`
- `mitmdump`
- `wireshark-cli`

### Static analysis

- `jadx` (includes `jadx-gui`)
- `apktool`
- `ghidra-bin`
- `radare2`
- `cutter`
- `binwalk`

### Android build tools

- `aapt`, `aapt2`
- `apksigner`
- `zipalign`

### Runtime instrumentation

- `objection`

### Device UI automation (structured agent interaction)

- `agent-device` — CLI for structured accessibility-tree interaction with Android devices
  - Always load the `agent-device` skill before interacting with the device UI: the skill provides the canonical command reference and workflow
  - `snapshot -i` dumps interactive a11y tree elements with stable `@eN` refs (always snapshot before interacting)
  - `click @eN`, `fill @eN "text"`, `type "text"`, `scroll down 0.5` for UI interaction via refs
  - `find <text> <action>` for semantic element lookup
  - `screenshot --out path.png`, `wait text "Settings"`, `alert get` for observation
  - `open Settings --platform android` to launch apps, `close` to end sessions
  - `devices` to list available devices, `appstate` for foreground app info
  - `boot --platform android` to boot an emulator (requires a running AVD)
  - Prefer `agent-device` over raw `adb shell input` for any UI navigation task
  - Use `adb` for low-level tasks (push/pull, shell, root, logcat, forward) — `agent-device` does not replace `adb`
  - iOS platform (`--platform ios`) is not available on this Linux host; requires macOS + Xcode

### Device spoofing (emulator identity masking)

- `re-avd.sh spoof` — patches emulator system props to look like a real Pixel 7
  - Spoofs 45+ system properties (hardware, model, fingerprint, serial, etc.)
  - Hides emulator-indicator files (`/dev/goldfish_pipe`, `/dev/qemu_pipe`, etc.)
  - Stops emulator-specific services (`goldfish-logcat`, `qemu-adb-setup`, `ranchu-*`, etc.)
  - Applied automatically on `re-avd.sh start` (controlled by `RE_SPOOF_DEVICE=1`)
  - Uses Magisk `resetprop` via `/data/adb/magisk` multi-call binary
  - Run `re-avd.sh spoof` manually at any time to re-apply after changes
  - Run `re-avd.sh unspoof` to restore hidden files (props need emulator reboot to fully revert)

### Utility tools used by the workflow

- `sqlite3`
- `unzip`
- `xz`
- `scrcpy`

## Installed But Important To Note

- `scrcpy` is for manual inspection, not unattended automation
- `sqlite3` comes from Android platform tools in this environment
- Frida server is staged locally under `~/Downloads/android-re-tools/frida/`
- The currently working Frida path is `17.5.1` (system tools + matching server binary)
- The ARM64 server binary is staged, but a native ARM64 AVD is not runnable on this host's current emulator backend
- The Linux emulator path now works on host NVIDIA rendering instead of forced software fallback
- OpenCode Android RE sessions are launched through `ocare`, `ocgptare`, `ocglmare`, `ocgemare`, `ocorare`, `ocsare`, and `oczenare`
- `agent-device` wraps `adb` for structured UI interaction (snapshot, click, fill, find) but does not replace `adb` for low-level tasks (push/pull, shell, root, logcat, forward). Use `agent-device` for navigating apps and `adb` for everything else.
- Device spoofing is applied automatically on `start` via `RE_SPOOF_DEVICE=1`. After spoofing, `agent-device` will report the device as a real Pixel 7 instead of the emulator. Some apps may still detect the emulator through runtime checks that go beyond system props — use Frida hooks for those.

## Not Currently Available In PATH

At the time this workspace was written, these were not found in PATH:

- `dex2jar`

## Recommended Additions

### High value

1. `dex2jar`
   Reason: alternate DEX conversion path when JADX output is awkward or partial.

### Nice to have

1. `mobsf`
   Reason: broad static triage and reporting.

2. `rizin`
   Reason: alternative native analysis workflow to `radare2`.

3. `burpsuite`
   Reason: second interception path with familiar repeater/intruder style workflows.

## Suggested Nix Changes

If you want these managed declaratively, the likely places are:

- `home-manager/packages/development.nix` for RE tooling
- `home-manager/packages/cli.nix` for CLI and proxy tooling
- `nixos-modules/android.nix` for system-level Android SDK integration

## Important Constraints

- Google emulator ARM64 AVD boot is not currently supported on this `x86_64` Linux host with the installed emulator/QEMU2 stack.
- The rooted baseline RE path on this machine remains the `x86_64` AVD.
- Some ARM-only apps may run via translation on `google_apis/x86_64`, but that is not equivalent to a native ARM guest.
- HTTPS interception is available, but proxying is now opt-in rather than forced during startup.
