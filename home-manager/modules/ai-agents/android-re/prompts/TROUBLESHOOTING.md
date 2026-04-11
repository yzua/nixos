# Android RE Troubleshooting

## Emulator Does Not Appear In `adb devices`

Check:

```bash
adb devices -l
bash scripts/ai/android-re/re-avd.sh status
# If launched via oc*are, check the background boot log:
tail -f ~/Downloads/android-re-tools/re-avd-start.log
```

If needed, start manually:

```bash
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
adb shell "su 0 sh -c 'ps -A | grep frida'"
```

Check server log:

```bash
adb shell "su 0 sh -c 'tail -30 /data/local/tmp/frida.log'"
```

Common causes:

- wrong Frida server version for host tools
- wrong ABI
- old server process still bound to port 27042

Fix:

```bash
# Kill any stale server
adb shell "su 0 sh -c 'pkill -x frida-server-17.5.1'"
sleep 1

# Restart via re-avd.sh
bash scripts/ai/android-re/re-avd.sh frida-start

# Verify version match
frida --version
adb shell "su 0 sh -c '/data/local/tmp/frida-server-17.5.1 --version'"
# Both should print 17.5.1
```

## Frida Attach Fails Or Times Out

```bash
# Try by PID instead of name
frida-ps -U | grep com.example.target
frida -U -p <pid>

# Try spawn mode (fresh start with injection)
frida -U -f com.example.target -l hook.js --no-pause

# Try emulated realm (for ARM translation)
frida -U -n com.example.target --realm=emulated
```

If `frida -U` hangs:

```bash
# Verify server is actually running
adb shell "su 0 sh -c 'ps -A | grep frida'"
# If not running, restart it:
bash scripts/ai/android-re/re-avd.sh frida-start
```

If attach returns "unexpectedly timed out":

- Heavy processes (Chrome, system_server) may timeout on first attach — retry once
- Try a lighter target or use `-f` spawn mode
- Check if the app has anti-Frida detection running

## Frida Works But `frida-ps -U` Is Empty

```bash
# Verify USB connection
adb devices -l

# Restart adb and frida
adb kill-server && adb start-server
sleep 2
bash scripts/ai/android-re/re-avd.sh frida-start
frida-ps -U
```

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

### Step 1: Verify proxy is set on device

```bash
adb shell settings get global http_proxy
# Expected when enabled: 10.0.2.2:8084
# If :0 or null, proxy is not set
```

### Step 2: Verify mitmdump is listening

```bash
ss -ltnH '( sport = :8084 )'
# Should show a listener. If empty, mitmdump is not running.
```

### Step 3: Restart mitmdump if needed

```bash
tmux send-keys -t android-re:mitm C-c
sleep 1
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=2" Enter
```

### Step 4: Force-stop and restart the target app

The app may have cached connections from before proxy was enabled:

```bash
adb shell am force-stop com.example.target
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
```

### Step 5: Check if QUIC bypass is blocked

Some apps use QUIC (UDP/443) which bypasses HTTP proxy:

```bash
adb shell "su 0 iptables -L OUTPUT -n | grep 443"
# Should show REJECT rule for udp dpt:443
```

If missing, apply:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
```

### Step 6: Check the mitmproxy pane for errors

```bash
tmux capture-pane -t android-re:mitm -p -S -40
```

Look for:
- `Client TLS handshake failed` → certificate pinning (app doesn't trust mitmproxy CA)
- `client disconnected` → app retrying or rejecting the connection
- `connection refused` → mitmdump not running or wrong port

### Step 7: If still no traffic

- App may use a hardcoded proxy or direct IP (ignore system proxy settings)
- App may use Cronet or a custom HTTP client that ignores system proxy
- Check logcat for network errors: `tmux capture-pane -t android-re:logcat -p -S -40`
- Try `mitmproxy` in transparent mode or use iptables-based redirection (advanced)

## All Traffic Shows "Client TLS Handshake Failed"

This means the app does NOT trust the mitmproxy CA certificate. Debug:

```bash
# 1. Verify CA is in system cert store
bash scripts/ai/android-re/re-avd.sh cert-check

# 2. Verify conscrypt bind mount is active
adb shell "su 0 mountpoint /apex/com.android.conscrypt/cacerts"
# Should print: /apex/com.android.conscrypt/cacerts is a mountpoint

# 3. If mount is missing, re-sync the CA
bash scripts/ai/android-re/re-avd.sh start
# Or manually:
bash scripts/ai/android-re/re-avd.sh cert-check
```

If cert is installed but app still fails:
- App uses certificate pinning — check static analysis for `CertificatePinner`, `TrustManager`, or native pinning
- App may pin specific public keys, not just CAs
- Use Frida to bypass pinning (see WORKFLOW.md hooking patterns)

### Google domains always fail

Chrome pins certificates for `*.google.com` domains. This is expected and cannot be bypassed by CA injection alone. Non-Google sites should decrypt fine.

## mitmproxy Shows Traffic But Responses Are Errors

```bash
# Read the full request/response cycle
tmux capture-pane -t android-re:mitm -p -S -100 | grep -A5 '<< HTTP'

# Common patterns:
# 403/401 → App needs auth, token expired, or device binding
# 400 → Malformed request, missing headers, wrong API version
# 403 + "request blocked" → WAF/bot detection, may need user-agent or device spoofing
# Connection reset → Server-side anti-MITM detection
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
