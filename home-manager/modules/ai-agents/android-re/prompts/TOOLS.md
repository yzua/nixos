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

### Utility tools used by the workflow

- `sqlite3`
- `unzip`
- `xz`
- `scrcpy`

## Installed But Important To Note

- `scrcpy` is for manual inspection, not unattended automation
- `sqlite3` comes from Android platform tools in this environment
- Frida server is staged locally under `~/Downloads/android-re-tools/frida/`
- The currently working pinned Frida path is still `16.4.10`
- The ARM64 server binary is staged, but a native ARM64 AVD is not runnable on this host's current emulator backend
- The Linux emulator path now works on host NVIDIA rendering instead of forced software fallback
- OpenCode Android RE sessions are launched through `ocare`, `ocgptare`, `ocglmare`, `ocgemare`, `ocorare`, `ocsare`, and `oczenare`

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
