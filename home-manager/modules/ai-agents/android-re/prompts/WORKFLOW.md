# Android RE Workflow

## Goals

This workflow exists to turn Android RE sessions into short, evidence-backed
loops instead of random command spraying.

Primary outputs per target:

- package identity, version, and ABI
- install and launch status
- exported components and interesting manifest flags
- likely network stack and endpoint surface
- proxy result: visible traffic / handshake failure / bypass / no traffic
- Frida result: attach works / spawn works / blocked / emulated realm needed
- anti-analysis result: root, emulator, Frida, pinning, native guards
- next best action with proof

## Phase 0: Environment Validation

Run:

```bash
bash scripts/ai/android-re/re-avd.sh doctor
bash scripts/ai/android-re/re-avd.sh status
```

Confirm:

- `adb`, `emulator`, `mitmproxy`, `mitmdump`, `frida`, `jadx`, `apktool`
- local Frida server binary exists
- custom CA exists
- configured AVD exists
- `adb devices` sees the emulator
- `sys.boot_completed=1`
- `adb shell 'su 0 sh -c id'` works

If any baseline check fails, stop and use `TROUBLESHOOTING.md` before touching a
target app.

## Phase 1: Boot And Observe The Emulator

If launched via `oc*are`, the emulator is already starting in the background.
Verify readiness:

```bash
bash scripts/ai/android-re/re-avd.sh status
tail -f ~/Downloads/android-re-tools/re-avd-start.log
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
```

If starting manually:

```bash
bash scripts/ai/android-re/re-avd.sh start
bash scripts/ai/android-re/re-avd.sh status
```

Healthy state means:

- AVD listed and online in `adb devices`
- boot property `sys.boot_completed=1`
- unattended root works
- proxy state is known
- tmux session `android-re` exists with `mitm`, `frida`, `logs`, `logcat`

## Phase 2: Target Intake

Before hooks or interception, identify the target precisely.

If you have an APK:

```bash
bash scripts/ai/android-re/re-static.sh prepare /path/to/app.apk
bash scripts/ai/android-re/re-static.sh hashes /path/to/app.apk
```

If the app is already installed:

```bash
adb shell pm list packages | grep example
adb shell dumpsys package com.example.target | grep versionName
adb shell dumpsys package com.example.target | rg "primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir|split_config"
adb shell pm path com.example.target
adb shell getprop ro.product.cpu.abi
```

Capture:

- package name
- version
- ABI
- install path / split APK paths
- whether it likely depends on ARM translation

Pivot rule:

- if the app is ARM-only on this `x86_64` guest, treat instability as a real
  possibility and verify ABI before blaming root, proxy, or Frida.

## Phase 3: Static Triage First

Before dynamic hooking, inspect the APK output. This is where you decide which
runtime path is worth exercising.

Look for:

- `AndroidManifest.xml`
- exported activities, services, receivers, providers
- deep links and intent filters
- `networkSecurityConfig` and cleartext policy
- authentication and token classes
- certificate pinning code paths
- root / emulator / Frida detection strings
- native libraries under `lib/`

Common searches:

```bash
grep -R "TrustManager\|CertificatePinner\|X509TrustManager" ~/.cache/android-re/out/<app>/jadx
grep -R "frida\|magisk\|su\|test-keys\|ro.debuggable" ~/.cache/android-re/out/<app>/jadx
grep -R "okhttp\|retrofit\|cronet\|quic" ~/.cache/android-re/out/<app>/jadx
grep -R "root\|emulator\|isDebuggerConnected\|ptrace" ~/.cache/android-re/out/<app>/jadx
```

Static triage questions:

1. Is the app likely Java-heavy, native-heavy, or mixed?
2. Does it look like standard OkHttp/Retrofit or Cronet/native TLS?
3. Are there obvious pinning or root-check classes?
4. Do native libs suggest JNI-heavy auth or anti-analysis logic?

Pivot rule:

- if static analysis shows Cronet, BoringSSL, or native networking, assume Java
  MITM guidance may be insufficient and be ready to pivot to native analysis.

## Phase 4: Install, Launch, And Smoke Test

Install and launch cleanly before proxying or hooking.

```bash
adb install -r /path/to/app.apk
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
adb shell pidof com.example.target
tmux capture-pane -t android-re:logcat -p -S -80
```

Or use structured UI navigation:

```bash
agent-device open com.example.target --platform android
agent-device snapshot -i
agent-device screenshot --out /tmp/initial-screen.png
agent-device close
```

Capture:

- does it launch, crash, hang, or immediately complain about environment
- does `logcat` show TLS, root, tamper, debugger, or ABI failures
- which screen you reached

Pivot rule:

- if the app crashes before any traffic, go to `logcat` and static code first;
  do not jump to proxy setup as if the network layer is the issue.

## Phase 5: Prepare Network Interception

Default recommendation for this emulator:

- use explicit proxy mode first
- use the custom CA under `~/Downloads/android-re-tools/custom-ca/`
- use the verified listener on `8084`
- block QUIC when testing apps that may bypass via UDP/443

Set proxy:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
adb shell settings get global http_proxy
```

Expected:

```text
10.0.2.2:8084
```

Read the mitm pane:

```bash
tmux capture-pane -t android-re:mitm -p -S -200
tmux capture-pane -t android-re:mitm -p -S -300 | grep -oP '(?:GET|POST|PUT|DELETE|PATCH|HEAD) https?://[^ ]+' | sort -u
tmux capture-pane -t android-re:mitm -p -S -300 | grep -iE 'authorization|bearer|x-api-key|token'
```

Interpretation:

- visible decrypted traffic -> interception works
- `Client TLS handshake failed` -> trust/pinning issue
- no traffic at all -> proxy bypass, Cronet/native path, cached connections, or
  app not actually reaching the network
- `client disconnected` -> retry, app rejection, or partial interception

Pivot rule:

- if no traffic appears, prove proxy state, mitmdump listener state, and app
  restart before concluding certificate pinning.

## Phase 6: Exercise The App Deliberately

After static triage identifies important screens or flows, use `agent-device` to
trigger real behavior while proxy and logs are active.

```bash
agent-device open com.example.target --platform android
agent-device snapshot -i
agent-device find "Login" click
agent-device snapshot -i
agent-device fill @e5 "user@example.com"
agent-device fill @e7 "password123"
agent-device find "Submit" click
agent-device screenshot --out /tmp/after-submit.png
agent-device close
```

While doing this, read:

```bash
tmux capture-pane -t android-re:mitm -p -S -120
tmux capture-pane -t android-re:logcat -p -S -120
```

Use the screen interaction to answer concrete questions:

- what request fires on login
- which domains or hosts appear
- whether tokens are visible in headers or storage
- whether runtime defenses trigger only on specific screens

## Phase 7: Prepare Frida

Use the system Frida `17.5.1` toolchain only.

Before inventing new hooks, try the local hook library in
`scripts/ai/android-re/` first. It gives fast proof for common build-field,
filesystem, shared-preferences, URL, and certificate-pinning questions.

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
frida --version
frida-ps -U | head -20
adb shell "su 0 sh -c 'ps -A | grep frida'"
```

Attach modes:

```bash
# Attach to a running process
frida -U -n com.example.target

# One-shot inline probe
frida -U -n com.example.target -q -e 'console.log("attached")'

# Spawn mode for early bypasses
frida -U -f com.example.target -l hook.js

# Emulated realm for translated code paths
frida -U -n com.example.target --realm=emulated
```

Use tmux for long-running hooks:

```bash
tmux send-keys -t android-re:frida C-c
tmux send-keys -t android-re:frida "frida -U -n com.example.target" Enter
sleep 3
tmux capture-pane -t android-re:frida -p -S -60
```

Pivot rule:

- if attach fails, try PID, spawn, then `--realm=emulated` before assuming Frida
  detection.

## Phase 8: Anti-Analysis And Hooking

Only move here after static analysis or runtime evidence points to a concrete
guard worth bypassing.

Prefer this order:

1. reusable local hook library
2. target-specific inline or file-backed Frida hooks
3. external research on official docs, GitHub, CVEs, advisories, or known bypass patterns
4. subagents for deeper static/native/protocol analysis when a branch becomes too
   deep for the main session

### Common Java targets

- `okhttp3.CertificatePinner`
- custom `TrustManager` implementations
- root-check helper classes
- `android.os.Build`
- `java.io.File.exists`
- package and process checks for Magisk/Frida

### Common anti-analysis patterns

- root file checks: `su`, `magisk`, `busybox`, writable system paths
- emulator checks: `Build.*`, `ro.kernel.qemu`, qemu file paths, sensor absence
- Frida checks: process names, open ports, loaded classes, timing anomalies
- pinning: `CertificatePinner`, custom trust managers, native SSL verification
- bypass paths: QUIC, Cronet, direct sockets, native TLS

### Quick recon hooks

```bash
# What Build fields does the app see?
frida -U -n com.example.target -q -e '
Java.perform(function(){
  var B = Java.use("android.os.Build");
  console.log("MODEL=" + B.MODEL.value + " HARDWARE=" + B.HARDWARE.value + " BRAND=" + B.BRAND.value);
});
'

# Log Java URL creation
frida -U -n com.example.target -q -e '
Java.perform(function(){
  var URL = Java.use("java.net.URL");
  URL.$init.overload("java.lang.String").implementation = function(u){
    console.log("[URL] " + u);
    return this.$init(u);
  };
});
'
```

### Native pivot conditions

Move to native hooks or binary analysis when:

- Java hooks only hit wrappers
- static analysis shows JNI-heavy auth or pinning
- the app uses Cronet or native TLS
- pinning appears to live in native libs
- Java-level bypasses do not change runtime behavior

## Phase 9: Prove Findings With POC Scripts

When you find interesting behavior, write a script to prove it. Do not stop at
describing the finding.

Available runtimes:

- Bash
- Python 3.13
- Node.js 24
- Bun 1.3.10
- Frida JS

Typical POC patterns:

```bash
# Replay a captured request
curl -s "https://api.example.com/v1/users/me" | jq .

# Iterate an IDOR candidate
for i in $(seq 1 10); do
  curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/v1/users/$i" | jq '.email'
done

# Use a Frida script file for repeatable runtime capture
frida -U -n com.example.target -l /tmp/hook.js -q
```

The final deliverable should be operator-usable evidence, not just notes.
