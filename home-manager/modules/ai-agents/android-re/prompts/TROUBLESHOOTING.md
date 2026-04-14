# Android RE Troubleshooting

Use this file as a symptom -> proof -> next action guide. Do not apply fixes
blindly. Confirm the failure mode first, then choose the smallest recovery step.

## Emulator Does Not Appear In `adb devices`

Prove the current state:

```bash
adb devices -l
bash scripts/ai/android-re/re-avd.sh status
tail -f ~/Downloads/android-re-tools/re-avd-start.log
```

If the emulator was never started:

```bash
bash scripts/ai/android-re/re-avd.sh start
```

If `adb` looks stale:

```bash
adb kill-server
adb start-server
adb devices -l
```

Likely causes:

- emulator still booting
- stale `adb` server state
- AVD failed before full boot

## AVD Exists But Does Not Boot Fully

Proof:

```bash
adb shell getprop sys.boot_completed
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
adb logcat -b all -v threadtime
```

Healthy value:

```text
1
```

If stuck:

- restart the emulator
- inspect lock files under `~/.android/avd/`
- confirm disk space and runtime logs

Host-specific note:

```text
Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.
```

Do not chase ARM64 boot work on this host unless the emulator backend changes.

## `su` Stops Working

First prove the invocation syntax:

```bash
adb shell 'su 0 sh -c id'
```

Do not use:

```bash
adb shell 'su -c id'
```

If unattended root broke:

1. verify `adb root`
2. inspect `bash scripts/ai/android-re/re-avd.sh status`
3. use `TROUBLESHOOTING.md` and the Magisk DB path only if status proves policy
   drift

## `adb root` Works But Magisk Feels Broken

Symptoms:

- `adb root` succeeds
- `magisk --sqlite` or app-side checks fail
- `su` prompts or denies unexpectedly

Try:

```bash
adb reboot
bash scripts/ai/android-re/re-avd.sh status
```

Likely causes:

- Magisk app and ramdisk state drifted
- reboot required after DB or app change
- app-side root checks are failing for reasons other than ADB shell root

## Frida Server Does Not Start

Prove the failure:

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
frida-ps -U
adb shell "su 0 sh -c 'ps -A | grep frida'"
adb shell "su 0 sh -c 'tail -30 /data/local/tmp/frida.log'"
```

Common causes:

- wrong Frida server version
- wrong ABI
- stale server process still bound to port `27042`

Recovery:

```bash
adb shell "su 0 sh -c 'pkill -x frida-server-17.5.1'"
sleep 1
bash scripts/ai/android-re/re-avd.sh frida-start
frida --version
adb shell "su 0 sh -c '/data/local/tmp/frida-server-17.5.1 --version'"
```

Both version commands should print `17.5.1`.

## Frida Attach Fails Or Times Out

Prove the exact failure mode:

```bash
frida-ps -U | grep com.example.target
frida -U -n com.example.target
frida -U -p <pid>
frida -U -f com.example.target
frida -U -n com.example.target --realm=emulated
tmux capture-pane -t android-re:frida -p -S -80
```

Interpretation:

- attach by name fails, PID works -> process enumeration or package-name mismatch
- attach fails, spawn works -> early anti-Frida or timing issue
- only `--realm=emulated` works -> translated ARM path
- everything fails -> server state, ABI mismatch, or hard anti-analysis

Do not assume `frida-ps -U` alone proves real hookability.

## Hooks Load But Do Not Fire

Proof checklist:

```bash
tmux capture-pane -t android-re:frida -p -S -80
tmux capture-pane -t android-re:logcat -p -S -120
tmux capture-pane -t android-re:mitm -p -S -120
```

Likely causes:

- hooked the wrong class or overload
- hooked after the target code already ran
- Java layer only wraps native logic
- app path differs from the one you exercised

Next actions:

- move from attach to spawn for earlier injection
- verify class names from static analysis
- log broader signals first (`URL`, `Build`, filesystem checks)
- pivot to native triage if Java hooks remain silent

## `frida-ps -U` Works Once But Not After Reboot

Check boot persistence:

```bash
adb root
adb shell 'ls -l /data/adb/service.d/frida.sh'
bash scripts/ai/android-re/re-avd.sh frida-start
```

If missing, re-stage the server or boot script via the existing helper flow.

## `mitmproxy` Does Not See Traffic

### Step 1: verify device proxy state

```bash
adb shell settings get global http_proxy
```

Expected when enabled:

```text
10.0.2.2:8084
```

### Step 2: verify listener state

```bash
ss -ltnH '( sport = :8084 )'
tmux capture-pane -t android-re:mitm -p -S -80
```

### Step 3: restart the target app after enabling proxy

```bash
adb shell am force-stop com.example.target
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
```

### Step 4: verify QUIC blocking

```bash
adb shell "su 0 iptables -L OUTPUT -n | grep 443"
```

If missing:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
```

### Step 5: read `logcat`

```bash
tmux capture-pane -t android-re:logcat -p -S -120
```

If traffic is still absent, suspect:

- Cronet or native networking bypass
- direct IP or custom socket logic
- hardcoded proxy rules
- app never reaching the code path you expected

## All Traffic Shows `Client TLS Handshake Failed`

Prove trust state:

```bash
bash scripts/ai/android-re/re-avd.sh cert-check
adb shell "su 0 mountpoint /apex/com.android.conscrypt/cacerts"
```

If mount is missing or CA state looks stale:

```bash
bash scripts/ai/android-re/re-avd.sh start
bash scripts/ai/android-re/re-avd.sh cert-check
```

If cert installation looks correct but failures remain, suspect:

- certificate pinning
- custom trust manager
- native TLS validation
- domain-specific anti-MITM logic

Google domains are expected to pin aggressively. Use non-Google domains as the
baseline signal for whether your CA path works.

## mitmproxy Shows Traffic But Responses Are Errors

Proof:

```bash
tmux capture-pane -t android-re:mitm -p -S -120 | grep -A5 '<< HTTP'
```

Interpretation:

- `401` / `403` -> auth, token, or device binding issue
- `400` -> malformed replay or wrong request shape
- `403` with anti-bot messaging -> WAF or environment fingerprinting
- connection reset -> server-side anti-MITM or protocol mismatch

Do not call this a proxy failure unless the request never decrypted.

## App Detects The Emulator

Prove spoof state:

```bash
adb shell getprop ro.hardware
adb shell getprop ro.product.model
adb shell getprop ro.build.characteristics
adb shell getprop ro.kernel.qemu
```

Expected direction:

- Pixel 7-style values
- `ro.kernel.qemu=0`

If needed:

```bash
bash scripts/ai/android-re/re-avd.sh spoof
```

If the app still detects the emulator, suspect:

- Java `Build.*` checks seeing cached values
- file existence checks like `/dev/goldfish_pipe` or `/dev/qemu_pipe`
- sensor or hardware heuristics
- native ABI or timing checks

Next actions:

- use `scripts/ai/android-re/frida-spoof-build.js`
- hook `java.io.File.exists`
- check static analysis for detection helpers or native libs

## Root Checker Says The Device Is Not Rooted

If `adb shell 'su 0 sh -c id'` works but app-side root checks fail, prove the
environment:

```bash
adb shell getenforce
adb logcat -d -v threadtime | rg 'su_exec|root|magisk'
```

Known cause on this emulator:

- app-side checks can fail because SELinux blocks expected root-path access even
  while unattended ADB shell root still works

Current default fix path:

- `re-avd.sh start` sets guest SELinux to permissive by default
- override with `RE_SELINUX_PERMISSIVE=0` only when you explicitly want
  enforcing mode

## CA Is Installed But TLS Still Fails

Prove both cert locations:

```bash
adb shell 'ls -l /system/etc/security/cacerts'
adb shell 'ls /apex/com.android.conscrypt/cacerts | tail'
```

Then ask:

- is the custom CA really the one mitmdump is using
- was the namespace remount applied after the latest start
- does static analysis point to pinning or native trust logic
- is the failing domain protected differently from the rest of the app

## `agent-device` Cannot Find The Emulator

Proof:

```bash
agent-device devices --platform android
adb devices -l
```

If empty:

- confirm the emulator is fully booted
- confirm `ANDROID_SERIAL` or `ANDROID_DEVICE` are not set incorrectly
- remember `agent-device` depends on `adb` visibility

If commands fail after discovery:

```bash
agent-device open Settings --platform android --debug
```

Then inspect logs under `~/.agent-device/logs/`.

## Emulator Falls Back To Slow Software Rendering

Proof:

```bash
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
```

Healthy Linux rendering currently looks like:

- `Graphics Adapter Vendor Google (NVIDIA Corporation)`
- `Graphics Adapter Android Emulator OpenGL ES Translator (NVIDIA GeForce RTX 2070/PCIe/SSE2)`

If you see `lavapipe` or `swangle`, try:

```bash
EMU_DISABLE_VULKAN=1 bash scripts/ai/android-re/re-avd.sh start
EMU_GPU_MODE=software bash scripts/ai/android-re/re-avd.sh start
```

## App Installs On One AVD But Not Another

Prove ABI mismatch first:

```bash
adb shell dumpsys package com.example.target | rg "primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir|split_config"
adb shell getprop ro.product.cpu.abi
adb shell getprop ro.product.cpu.abilist
```

Known pattern on this host:

- translated ARM-only packages can behave differently across `x86_64` AVDs
- some packages may fail with `INSTALL_FAILED_NO_MATCHING_ABIS`

## Generic Ownership Boundary

This baseline owns:

- emulator health
- root and cert setup
- Frida server orchestration
- `mitmproxy` setup
- static APK extraction

Target-specific startup hooks, token generation logic, and exploit automation
should live in target-specific scripts or workspaces rather than in this generic
bundle.
