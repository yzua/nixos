# Android RE Troubleshooting

## Emulator Does Not Appear In `adb devices`

Check:

```bash
adb devices -l
bash scripts/ai/android-re/re-avd.sh start
```

If needed:

```bash
adb kill-server
adb start-server
```

## AVD Exists But Does Not Boot Fully

Check:

```bash
adb shell getprop sys.boot_completed
```

If stuck:

- restart the emulator
- inspect recent emulator logs under `~/Downloads/android-re-tools/`
- confirm disk space and no stale lock files under `~/.android/avd/`

Additional logging:

```bash
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
adb logcat -b all -v threadtime
```

Host/ABI specific note:

- on this `x86_64` Linux host, a true ARM64 AVD will not boot with the current emulator backend
- fatal seen here:

```text
Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.
```

## `su` Stops Working

First verify the correct invocation:

```bash
adb shell 'su 0 sh -c id'
```

Do not use:

```bash
adb shell 'su -c id'
```

If unattended root breaks again:

1. check `adb root`
2. pull `/data/adb/magisk.db`
3. verify `policies` includes UID `2000` with policy `2`
4. push the DB back and reboot

## `adb root` Works But Magisk Feels Broken

Symptoms:

- `adb root` succeeds
- `magisk --sqlite` fails or daemon is incomplete
- `su` prompts or denies unexpectedly

Likely causes:

- Magisk app package and ramdisk state are out of sync for the current boot
- a reboot is required after app update or DB changes

Try:

```bash
adb reboot
bash scripts/ai/android-re/re-avd.sh status
```

## Frida Server Does Not Start

Check:

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
frida-ps -U
adb shell 'cat /data/local/tmp/frida.log'
```

Common causes:

- wrong Frida server version for host tools
- wrong ABI
- old server process still bound

Fix:

- replace the server binary with the matching host version
- restart it

Important emulator note:

- `frida-ps -U` success does not guarantee `attach` works
- use the system Frida `17.5.1` toolchain with the matching server binary at `~/Downloads/android-re-tools/frida/`
- the isolated `16.4.10` client venv is broken (missing python3.11) — do not use it

Known working commands:

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
frida-ps -U
frida -U -p <pid> -q -e 'Process.id'
```

If attach still fails with `connection closed`:

- verify you are using the system `frida` (v17.5.1), not the broken v16 venv
- verify the server is the `17.5.1` binary at `/data/local/tmp/frida-server-17.5.1`
- check for version mismatch: `frida --version` on host vs `adb shell 'su 0 /data/local/tmp/frida-server-17.5.1 --version'`

## Root Checker Says The Device Is Not Rooted

If `adb shell 'su 0 sh -c id'` works but Root Checker or the Magisk app still says root is missing, check SELinux first:

```bash
adb shell getenforce
adb logcat -d -v threadtime | rg 'su_exec|app=com.joeykrim.rootcheck|app=com.topjohnwu.magisk'
```

Known cause on this emulator:

- `untrusted_app` is denied `read/getattr/execute` on `/system/xbin/su`
- that breaks app-level root checks even though unattended ADB root still works

Current fix:

- `bash scripts/ai/android-re/re-avd.sh start` now switches the guest to `SELinux=Permissive` by default
- override with `RE_SELINUX_PERMISSIVE=0` if you explicitly want enforcing mode
- keep the server in the foreground while testing if needed

## `frida-ps -U` Works Once But Not After Reboot

Check boot script:

```bash
adb root
adb shell 'ls -l /data/adb/service.d/frida.sh'
```

If missing, recreate it and reboot.

## `mitmproxy` Does Not See Traffic

Check explicit proxy:

```bash
adb shell settings get global http_proxy
```

Expected on default startup:

- `:0`

Set it when you want interception:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
```

If still empty:

- app may ignore global proxy
- app may use QUIC or Cronet
- app may pin certificates

If the app still fails while proxy is set, check both logs:

```bash
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
adb logcat -b all -v threadtime
```

## App Detects The Emulator

If an app refuses to run or shows "emulator detected":

1. Verify spoofing was applied:

```bash
adb shell getprop ro.hardware           # should show "pixel" not "ranchu"
adb shell getprop ro.product.model      # should show "Pixel 7"
adb shell getprop ro.build.characteristics  # should show "nosdcard,phone"
adb shell getprop ro.kernel.qemu        # should show "0"
```

1. Re-apply if needed:

```bash
bash scripts/ai/android-re/re-avd.sh spoof
```

1. If the app still detects the emulator, it's likely using runtime checks beyond system props:
   - File existence checks (`/dev/goldfish_pipe`, `/dev/qemu_pipe`)
   - Sensor checks (accelerometer, gyroscope patterns)
   - CPU/ABI checks via native code
   - Timing-based detection

1. For runtime detection, use Frida hooks on:
   - `android.os.Build` fields
   - `java.io.File.exists` for emulator-indicator paths
   - Sensor data injection
   - Any native detection functions found in static analysis

## `agent-device` Cannot Find The Emulator

```bash
agent-device devices --platform android
```

If empty:

1. Verify the emulator is running: `adb devices`
2. `agent-device` discovers devices through `adb` — the emulator must be fully booted
3. If booted but not found, check `ANDROID_SERIAL` or `ANDROID_DEVICE` env vars aren't set to a wrong value

If `agent-device` shows the device but commands fail:

```bash
agent-device open Settings --platform android --debug
```

Check the diagnostic logs under `~/.agent-device/logs/`.

## Target-Specific Reverse Engineering Logic

If a target needs app-specific startup hooks, token generation, or protocol replay logic, keep that in a target-specific workspace or script instead of reintroducing it into this generic Android RE baseline.

Generic workflow ownership stops at:

- emulator health
- root and cert setup
- Frida server orchestration
- `mitmproxy` setup
- static APK extraction

## CA Is Installed But TLS Still Fails

Check:

```bash
adb shell 'ls -l /system/etc/security/cacerts'
adb shell 'ls /apex/com.android.conscrypt/cacerts | tail'
```

Then investigate:

- whether the cert was only copied to `/system/etc/security/cacerts` but not re-exposed from a tmpfs-backed system cert dir into Android 14 app namespaces
- whether you are still using the default `~/.mitmproxy` CA instead of the verified custom CA in `~/Downloads/android-re-tools/custom-ca/`
- pinning in Java or native code
- custom trust manager
- certificate transparency or domain-level anti-MITM logic

Recent evidence on this machine:

- after the clean Android 14 cert injection path, many Chromium and Google HTTPS requests decrypt correctly in `mitmproxy`
- if a specific domain still reports `certificate unknown`, check whether that process predates the latest namespace remount or is applying app-level trust logic

## Emulator Falls Back To Slow Software Rendering

Check the runtime log:

```bash
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
```

Healthy Linux host rendering now looks like:

- `Graphics Adapter Vendor Google (NVIDIA Corporation)`
- `Graphics Adapter Android Emulator OpenGL ES Translator (NVIDIA GeForce RTX 2070/PCIe/SSE2)`

If you instead see `lavapipe` or `swangle`:

- confirm the emulator is being launched through `bash scripts/ai/android-re/re-avd.sh start`
- confirm the NixOS `emulator` wrapper is current
- confirm `/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json` exists

Fallbacks:

```bash
EMU_DISABLE_VULKAN=1 bash scripts/ai/android-re/re-avd.sh start
EMU_GPU_MODE=software bash scripts/ai/android-re/re-avd.sh start
```

## App Installs On One AVD But Not Another

Check ABI before changing anything else:

```bash
adb shell dumpsys package com.example.target | rg "primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir|split_config"
adb shell getprop ro.product.cpu.abi
adb shell getprop ro.product.cpu.abilist
```

Known pattern discovered here:

- a clean `default/x86_64` AVD can reject translated ARM-only packages with `INSTALL_FAILED_NO_MATCHING_ABIS`
