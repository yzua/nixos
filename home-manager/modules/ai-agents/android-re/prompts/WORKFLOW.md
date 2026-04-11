# Android RE Workflow

## Goals

This workflow is for agents doing:

- app install and smoke testing
- network interception
- runtime instrumentation with Frida
- static APK inspection
- debugging root, proxy, and instrumentation failures

## 1. Environment Validation

Run:

```bash
bash scripts/ai/android-re/re-avd.sh doctor
```

Check for:

- `adb`, `emulator`, `avdmanager`, `sdkmanager`
- `mitmproxy` and `mitmdump`
- `frida` and `frida-ps`
- `apktool` and `jadx`
- local Frida server binary
- local `mitmproxy` CA
- configured AVD name

## 2. Boot The Emulator

Run:

```bash
bash scripts/ai/android-re/re-avd.sh start
```

Then verify:

```bash
bash scripts/ai/android-re/re-avd.sh status
```

Minimum healthy state:

- AVD listed
- emulator device online in `adb devices`
- boot property `sys.boot_completed=1`
- unattended root works
- proxy left at `:0` unless you explicitly enable interception

Additional host-side check:

```bash
tail -f ~/Downloads/android-re-tools/emulator-runtime.log
```

Healthy Linux graphics signal:

- `Graphics Adapter Vendor Google (NVIDIA Corporation)`
- `Graphics Adapter Android Emulator OpenGL ES Translator (NVIDIA GeForce RTX 2070/PCIe/SSE2)`

## 3. Launch The RE Agent Or Install The Target App

Preferred operator entrypoints:

```bash
ocare "triage this target"
ocgptare "focus on traffic, endpoints, and auth"
ocglmare "look for anti-analysis behavior"
oczenare "static-first APK triage"
```

These commands start the emulator baseline, spoof the device identity, and open Ghostty running OpenCode on the `android-re` agent using the prompt source in this directory.

For manual app interaction, use `agent-device` (load the skill first):

```bash
# Launch and navigate
agent-device open Settings --platform android
agent-device snapshot -i
agent-device find "Network" click
agent-device screenshot --out /tmp/screen.png
agent-device close
```

For manual install or launch with `adb`:

```bash
adb install -r /path/to/app.apk
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
```

Useful helpers:

```bash
adb shell pm list packages | grep example
adb shell dumpsys package com.example.target | grep versionName
adb shell pidof com.example.target
adb shell dumpsys package com.example.target | rg "primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir|split_config"
adb shell pm path com.example.target
adb shell getprop ro.product.cpu.abi
```

Interpretation guidance:

- if the guest ABI is `x86_64` but the package reports `primaryCpuAbi=arm64-v8a`, the app is not on a native ABI match
- on this host, translation can be good enough for many tasks but can still destabilize specific apps

## 4. Static Analysis First

Before dynamic hooking, unpack the APK:

```bash
bash scripts/ai/android-re/re-static.sh prepare /path/to/app.apk
```

Use the outputs to inspect:

- `AndroidManifest.xml`
- exported components
- network config and cleartext settings
- certificate pinning code paths
- root, emulator, and Frida detection strings
- native library names under `lib/`

Common searches:

```bash
grep -R "TrustManager\|CertificatePinner\|X509TrustManager" ~/.cache/android-re/out/<app>/jadx
grep -R "frida\|magisk\|su\|test-keys\|ro.debuggable" ~/.cache/android-re/out/<app>/jadx
grep -R "okhttp\|retrofit\|cronet\|quic" ~/.cache/android-re/out/<app>/jadx
```

## 5. Prepare Network Interception

Default recommendation for this emulator:

- do not rely on the default `~/.mitmproxy` CA
- use the custom CA under `~/Downloads/android-re-tools/custom-ca/`
- use the verified listener on `8084`

Start the proxy:

```bash
mitmdump --set confdir="$HOME/Downloads/android-re-tools/custom-ca" --listen-host 0.0.0.0 --listen-port 8084
```

Point the emulator at the host proxy:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
```

Or start the full stack with proxy enabled from the beginning:

```bash
RE_ENABLE_PROXY=1 bash scripts/ai/android-re/re-avd.sh start
```

Why:

- `10.0.2.2` maps emulator to host
- explicit proxy avoids extra routing complexity
- QUIC blocking prevents silent UDP/443 bypass on some apps and browsers

Verify proxy state:

```bash
adb shell settings get global http_proxy
```

Expected:

- `10.0.2.2:8084`

Clear it when done:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-clear
```

## 5b. Navigate And Exercise The App With agent-device

After static analysis identifies screens and flows of interest, use `agent-device` to navigate the app and trigger traffic while `mitmproxy` captures:

```bash
# Open the target app
agent-device open com.example.target --platform android

# Navigate to login or target screen
agent-device snapshot -i
agent-device find "Login" click
agent-device snapshot -i
agent-device fill @e5 "user@example.com"
agent-device fill @e7 "password123"
agent-device find "Submit" click

# Wait for response and capture
agent-device wait text "Welcome" 10000
agent-device screenshot --out /tmp/after-login.png
agent-device close
```

This lets you exercise app flows programmatically while `mitmproxy`, Frida, or `logcat` capture data in background tmux panes.

## 6. Prepare Frida

Important version note on this emulator:

- use the system Frida `17.5.1` toolchain for all attach and hook work
- server binary is at `~/Downloads/android-re-tools/frida/frida-server-17.5.1-android-x86_64`
- the isolated `16.4.10` toolchain venv is broken (missing python3.11) — do not use it
- ARM64 Frida server is staged locally, but a native ARM64 AVD cannot currently boot on this host's emulator backend

Start or restart Frida server:

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
```

In another shell:

```bash
frida-ps -U
```

Attach to app:

```bash
frida -U -n com.example.target
frida -U -p <pid>
frida -U -p <pid> -l hook.js -q
```

For translated or emulated code paths, try:

```bash
frida -U -n com.example.target --realm=emulated
```

## 7. Hooking Patterns

### Java layer

Use Frida Java hooks for:

- TLS bypass attempts
- root-check patching
- emulator-check patching
- logging request parameters
- short-circuiting feature flags

Typical targets:

- `okhttp3.CertificatePinner`
- custom `TrustManager` implementations
- root-check helper classes
- `android.os.Build`
- `java.io.File.exists`

### Native layer

Move to native hooks when:

- Java hooks show only thin wrappers
- pinning is implemented in native libraries
- the app uses Cronet, BoringSSL, or JNI-heavy auth paths
