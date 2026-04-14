# Android RE Tools

## Installed On This Machine

### Emulator and device control

- `adb`
- `emulator`
- `avdmanager`
- `sdkmanager`
- Android Studio

### Dynamic analysis

- `frida`, `frida-ps` (system `17.5.1`)
- rooted AVD with unattended `su 0 ...`

### Proxy and network

- `mitmproxy`, `mitmdump`, `mitmweb`
- `tshark`

### Static analysis

- `jadx` (includes `jadx-gui`)
- `apktool`
- `radare2`, `cutter`
- `binwalk`

### Android build tools

- `aapt`, `aapt2`
- `apksigner`
- `zipalign`

### Runtime instrumentation

- `objection`

### Device UI automation

- `agent-device` — load the `agent-device` skill before use

### Utility tools

- `sqlite3`, `unzip`, `xz`, `scrcpy`

## Tool Selection Guide

Use the smallest tool that gives a reliable answer:

- **Need package identity / version / paths / ABI?** Use `adb` and `dumpsys`
- **Need exported components or suspicious strings?** Use `re-static.sh`, `jadx`,
  `apktool`
- **Need to confirm live traffic?** Use `mitmdump` via the tmux `mitm` pane
- **Need runtime values or bypasses?** Use Frida attach or spawn
- **Need to click through the app reliably?** Use `agent-device`
- **Need repeated proof?** Write a small Bash/Python/Node/Bun/Frida script

## Tmux Session Layout

`re-avd.sh start` creates a tmux session called `android-re` with these windows:

| Window | Name     | Purpose                           |
| ------ | -------- | --------------------------------- |
| 0      | `shell`  | General shell, `adb` commands     |
| 1      | `mitm`   | `mitmdump` live traffic capture   |
| 2      | `frida`  | Frida REPL / hook output          |
| 3      | `logs`   | `tail -f` emulator runtime log    |
| 4      | `logcat` | `adb logcat -b all -v threadtime` |

### Reading tmux panes from the agent

You cannot attach interactively from the agent. Capture pane output instead:

```bash
tmux capture-pane -t android-re:mitm -p -S -80
tmux capture-pane -t android-re:logcat -p -S -80
tmux capture-pane -t android-re:frida -p -S -80
tmux capture-pane -t android-re:logs -p -S -80
tmux capture-pane -t android-re:shell -p -S -80
```

### Sending commands to tmux panes

```bash
tmux send-keys -t android-re:mitm C-c
tmux send-keys -t android-re:mitm "clear" Enter
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=2" Enter

tmux send-keys -t android-re:frida "frida -U -n com.example.target" Enter
tmux capture-pane -t android-re:frida -p -S -60
```

## Static Triage Recipes

### Extract and inventory an APK

```bash
bash scripts/ai/android-re/re-static.sh prepare /path/to/app.apk
bash scripts/ai/android-re/re-static.sh inventory
```

### Search by investigative goal

```bash
# Network stack and HTTP clients
grep -R "okhttp\|retrofit\|cronet\|quic" ~/.cache/android-re/out/<app>/jadx

# Trust and pinning
grep -R "TrustManager\|CertificatePinner\|X509TrustManager" ~/.cache/android-re/out/<app>/jadx

# Root / emulator / Frida detection
grep -R "frida\|magisk\|su\|test-keys\|ro.debuggable\|emulator\|qemu" ~/.cache/android-re/out/<app>/jadx

# Interesting exported components and deeplinks
grep -R "android.intent.action.VIEW\|BROWSABLE\|exported=\"true\"" ~/.cache/android-re/out/<app>
```

### What static analysis should answer

- is networking Java, native, or mixed
- where auth and token code likely lives
- whether pinning appears standard or custom
- whether detection is likely Java-only or native-backed
- whether the package ships significant native libraries

## mitmproxy Practical Usage

### Architecture

- `mitmdump` runs in tmux window `android-re:mitm`
- config dir: `~/Downloads/android-re-tools/custom-ca/`
- default listen: `0.0.0.0:8084`
- CA cert is injected into Android 14's conscrypt namespace on
  `re-avd.sh start`

### Enable / disable proxy

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
bash scripts/ai/android-re/re-avd.sh proxy-clear
adb shell settings get global http_proxy
```

Expected when enabled:

```text
10.0.2.2:8084
```

### Read captured traffic

```bash
tmux capture-pane -t android-re:mitm -p -S -300
tmux capture-pane -t android-re:mitm -p -S -300 | grep -oP '(?:GET|POST|PUT|DELETE|PATCH|HEAD) https?://[^ ]+' | sort -u
tmux capture-pane -t android-re:mitm -p -S -300 | grep 'POST https'
tmux capture-pane -t android-re:mitm -p -S -300 | grep '<< HTTP'
tmux capture-pane -t android-re:mitm -p -S -300 | grep -iE 'authorization|bearer|x-api-key|token'
```

### Interpret common output

- visible decrypted requests -> interception is working
- `Client TLS handshake failed` -> trust failure or pinning
- `client disconnected` -> app retrying, rejecting, or partially bypassing
- no output at all -> proxy not set, app not restarted, Cronet/native bypass, or
  app not making requests yet

### Restart mitmdump with different options

```bash
tmux send-keys -t android-re:mitm C-c
sleep 1
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=3" Enter
```

## Frida Practical Usage

## Local Frida Hook Library

Use the local hook library before writing one-off hooks from scratch. The goal
is to get quick proof, then adapt only when the target requires it.

Available scripts under `scripts/ai/android-re/`:

- `frida-hook-build-fields.js` — log `android.os.Build.*` values seen by the app
- `frida-hook-file-exists.js` — log root/emulator/frida file probes
- `frida-hook-shared-prefs.js` — log SharedPreferences reads and writes
- `frida-hook-url-log.js` — log URL construction and common OkHttp request URLs
- `frida-bypass-certificate-pinner.js` — bypass common OkHttp and Conscrypt trust checks
- `frida-spoof-build.js` — spoof Java-layer Build fields and hide emulator file paths

Example usage:

```bash
frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-build-fields.js -q
frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-url-log.js -q
frida -U -f com.example.target -l scripts/ai/android-re/frida-bypass-certificate-pinner.js
```

Rule:

- start with a local reusable hook
- only write target-specific hooks after a reusable hook proves the right layer
  or data path

External research is allowed when local paths are insufficient:

- search GitHub for similar apps, bypass hooks, or reverse-engineering notes
- search advisories and CVE writeups for vulnerable libraries, SDKs, WebViews,
  auth components, and mobile frameworks seen in the target
- use external results to generate hypotheses, then verify them locally against
  the target before treating them as findings

### Version rules

- system Frida: `17.5.1`
- server binary:
  `~/Downloads/android-re-tools/frida/frida-server-17.5.1-android-x86_64`
- remote path: `/data/local/tmp/frida-server-17.5.1`
- do not use the broken legacy `16.4.10` virtualenv

### Start and verify server

```bash
bash scripts/ai/android-re/re-avd.sh frida-start
frida --version
frida-ps -U | head -20
adb shell "su 0 sh -c 'ps -A | grep frida'"
adb shell "su 0 sh -c 'tail -20 /data/local/tmp/frida.log'"
```

### Attach modes

```bash
# Running process
frida -U -n com.example.target

# PID attach
frida -U -p 1234

# One-shot inline probe
frida -U -n com.example.target -q -e 'console.log("attached")'

# Script file
frida -U -n com.example.target -l /tmp/hook.js -q

# Spawn mode for early bypasses
frida -U -f com.example.target -l /tmp/hook.js

# Translated or emulated code path
frida -U -n com.example.target --realm=emulated
```

### Quick inline hooks

```bash
# What Build fields does the app see?
frida -U -n com.example.target -q -e '
Java.perform(function() {
  var B = Java.use("android.os.Build");
  console.log("MODEL=" + B.MODEL.value);
  console.log("HARDWARE=" + B.HARDWARE.value);
  console.log("MANUFACTURER=" + B.MANUFACTURER.value);
  console.log("BRAND=" + B.BRAND.value);
  console.log("DEVICE=" + B.DEVICE.value);
  console.log("FINGERPRINT=" + B.FINGERPRINT.value);
});
'

# Log Java URL creation
frida -U -n com.example.target -q -e '
Java.perform(function() {
  var URL = Java.use("java.net.URL");
  URL.$init.overload("java.lang.String").implementation = function(url) {
    console.log("[URL] " + url);
    return this.$init(url);
  };
});
'

# Basic root-file bypass
frida -U -n com.example.target -q -e '
Java.perform(function() {
  var File = Java.use("java.io.File");
  File.exists.implementation = function() {
    var path = this.getAbsolutePath();
    if (path.indexOf("su") >= 0 || path.indexOf("magisk") >= 0 || path.indexOf("supersu") >= 0) {
      console.log("[ROOT-BYPASS] " + path + " -> false");
      return false;
    }
    return this.exists();
  };
});
'
```

### When to pivot away from Java hooks

Pivot to native analysis when:

- static analysis shows JNI-heavy auth or trust logic
- Frida Java hooks only hit wrappers
- the app uses Cronet, BoringSSL, or native TLS
- URL logging sees nothing but traffic clearly exists
- pinning bypass attempts do not change behavior

## agent-device Practical Usage

### Always load the skill first

The `agent-device` skill provides the canonical command reference. Load it
before any UI interaction.

### Core workflow

```bash
agent-device devices --platform android
agent-device open com.example.target --platform android
agent-device snapshot -i
agent-device click @e3
agent-device fill @e5 "user@example.com"
agent-device find "Settings" click
agent-device screenshot --out /tmp/screen.png
agent-device close
```

### Rules

- always `snapshot -i` before interacting
- re-snapshot after UI changes
- prefer refs over coordinates
- use `find "label" click` for semantic lookup
- use `adb` for low-level tasks like push/pull, root, shell, and logcat

## adb Quick Reference

```bash
adb devices -l
adb shell getprop sys.boot_completed
adb install -r /path/to/app.apk
adb shell pm path com.example.target
adb shell pidof com.example.target
adb shell dumpsys package com.example.target | grep versionName
adb shell am force-stop com.example.target
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
adb shell 'su 0 sh -c id'
adb shell getenforce
adb push local.txt /data/local/tmp/
adb pull /data/local/tmp/file.txt ./
adb forward tcp:8080 tcp:8080
```

## Device Spoofing

- applied automatically on `re-avd.sh start`
- re-apply manually: `bash scripts/ai/android-re/re-avd.sh spoof`
- restore hidden files: `bash scripts/ai/android-re/re-avd.sh unspoof`
- Java `android.os.Build.*` fields may still expose emulator values because of
  Zygote caching

Use the Frida build spoof script when Java-level identity still leaks:

```bash
frida -U -f com.example.target -l scripts/ai/android-re/frida-spoof-build.js
frida -U -n com.example.target -l scripts/ai/android-re/frida-spoof-build.js
```

## Scripting And POC Development

You are expected to write and run custom scripts to validate findings. This is
core RE work.

### Available runtimes

| Runtime  | Version | Good for                                                  |
| -------- | ------- | --------------------------------------------------------- |
| Bash     | 5.3     | quick one-liners, adb/frida orchestration, pipelines      |
| Python 3 | 3.13    | replay tooling, crypto helpers, data parsing, automation |
| Node.js  | 24.13   | HTTP clients, JSON tooling, quick API testing            |
| Bun      | 1.3.10  | fast TS/JS execution and lightweight tooling              |

### Good POC targets

- replay captured requests with modified headers or IDs
- validate auth assumptions
- dump runtime values from Frida hooks
- exercise multiple package states repeatedly
- convert captured traffic into a reusable report or HAR file

Final rule: if a claim matters, automate the proof.
