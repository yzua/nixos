# Android RE Tools

## Installed On This Machine

### Emulator and device control

- `adb`
- `emulator`
- `avdmanager`
- `sdkmanager`
- Android Studio

### Dynamic analysis

- `frida`, `frida-ps` (system v17.5.1)
- rooted AVD with unattended `su 0 ...`

### Proxy and network

- `mitmproxy`, `mitmdump`, `mitmweb`
- `wireshark-cli`

### Static analysis

- `jadx` (includes `jadx-gui`)
- `apktool`
- `ghidra-bin`
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

---

## Tmux Session Layout

`re-avd.sh start` creates a tmux session called `android-re` with these windows:

| Window | Name    | Purpose                                       |
|--------|---------|-----------------------------------------------|
| 0      | `shell` | General shell, `adb` commands                 |
| 1      | `mitm`  | `mitmdump` live traffic capture               |
| 2      | `frida` | Frida REPL / hook output                      |
| 3      | `logs`  | `tail -f` emulator runtime log                |
| 4      | `logcat`| `adb logcat -b all -v threadtime`             |

### Reading tmux panes from the agent

You cannot interactively attach to tmux. Instead, **capture pane output** to read what's happening:

```bash
# Read the last 80 lines of mitmproxy output
tmux capture-pane -t android-re:mitm -p -S -80

# Read the last 40 lines of logcat
tmux capture-pane -t android-re:logcat -p -S -40

# Read Frida output
tmux capture-pane -t android-re:frida -p -S -40

# Read emulator runtime log
tmux capture-pane -t android-re:logs -p -S -40

# Read the shell pane
tmux capture-pane -t android-re:shell -p -S -40
```

### Sending commands to tmux panes

```bash
# Send a command to the mitm pane (e.g., restart with different options)
tmux send-keys -t android-re:mitm C-c        # Ctrl-C to stop current mitmdump
tmux send-keys -t android-re:mitm "clear" Enter  # clear screen
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=2" Enter

# Send a Frida command
tmux send-keys -t android-re:frida "frida -U -n com.example.target -e 'console.log(Process.id)'" Enter
```

---

## mitmproxy — Practical Usage Guide

### Architecture

- `mitmdump` runs inside tmux window `android-re:mitm`
- Config dir: `~/Downloads/android-re-tools/custom-ca/`
- Default listen: `0.0.0.0:8084`
- The CA cert is injected into Android 14's conscrypt namespace on `re-avd.sh start`

### Enabling/disabling proxy

```bash
# Enable proxy + QUIC blocking (prevents apps bypassing via UDP/443)
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic

# Disable proxy
bash scripts/ai/android-re/re-avd.sh proxy-clear

# Check current proxy setting
adb shell settings get global http_proxy
# Expected when enabled: 10.0.2.2:8084
# Expected when disabled: :0
```

### Reading captured traffic

```bash
# Get a snapshot of all captured requests
tmux capture-pane -t android-re:mitm -p -S -300

# Extract just the URL lines (deduplicated)
tmux capture-pane -t android-re:mitm -p -S -300 | grep -oP '(?:GET|POST|PUT|DELETE|PATCH|HEAD) https?://[^ ]+' | sort -u

# Extract only POST requests with their URLs
tmux capture-pane -t android-re:mitm -p -S -300 | grep 'POST https'

# Extract response codes
tmux capture-pane -t android-re:mitm -p -S -300 | grep '<< HTTP'

# Look for specific domains
tmux capture-pane -t android-re:mitm -p -S -300 | grep -i 'example.com'

# Look for auth headers or tokens
tmux capture-pane -t android-re:mitm -p -S -300 | grep -iE 'authorization|bearer|x-api-key|token'
```

### Restarting mitmdump with different options

```bash
# Stop current capture
tmux send-keys -t android-re:mitm C-c
sleep 1

# Start with verbose output (shows headers + bodies)
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=3" Enter

# Start with a filter (only capture specific domains)
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 --set flow_detail=2 '~d example.com'" Enter

# Start writing captures to file for later analysis
tmux send-keys -t android-re:mitm "mitmdump --set confdir=$HOME/Downloads/android-re-tools/custom-ca --listen-host 0.0.0.0 --listen-port 8084 -w /tmp/capture.flow" Enter
```

### Saving and reading capture files

```bash
# Save capture to file (add -w to mitmdump)
mitmdump ... -w /tmp/capture.flow

# Read a saved capture file
mitmdump -r /tmp/capture.flow --set flow_detail=3

# Convert capture to HAR format
mitmdump -r /tmp/capture.flow --set hardump=/tmp/capture.har
```

### What you'll see in mitmproxy output

Normal decrypted traffic looks like:

```
127.0.0.1:12345: GET https://api.example.com/v1/users HTTP/2.0
    user-agent: okhttp/4.11.0
    authorization: Bearer eyJhbG...
 << HTTP/2.0 200 OK 2.1k
    content-type: application/json
```

TLS handshake failure (cert pinning or trust issue):

```
Client TLS handshake failed. The client does not trust the proxy's certificate for accounts.google.com
```

This is **expected for Google domains** — Chrome pins certificates for `*.google.com`. Non-Google sites should decrypt fine.

Client disconnected (app retrying or connection issue):

```
127.0.0.1:12345: GET https://example.com/api
 << client disconnected
```

### Debugging "no traffic appears"

1. Check proxy is set: `adb shell settings get global http_proxy` → should be `10.0.2.2:8084`
2. Check mitmdump is listening: `ss -ltnH '( sport = :8084 )'`
3. Check QUIC is blocked: `adb shell "su 0 iptables -L OUTPUT -n | grep 443"`
4. Force-stop and restart the target app: `adb shell am force-stop com.example.target && adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1`
5. Check if the app uses certificate pinning (see static analysis section)
6. Read logcat for network errors: `tmux capture-pane -t android-re:logcat -p -S -40`

---

## Frida — Practical Usage Guide

### Version

- System Frida: `17.5.1` (`frida --version` to verify)
- Server binary: `~/Downloads/android-re-tools/frida/frida-server-17.5.1-android-x86_64`
- Remote path: `/data/local/tmp/frida-server-17.5.1`
- **Do NOT use** the broken v16.4.10 venv at `~/Downloads/android-re-tools/frida16410-py311/`

### Starting/stopping Frida server

```bash
# Start (deployed and started by re-avd.sh start automatically)
bash scripts/ai/android-re/re-avd.sh frida-start

# Stop
bash scripts/ai/android-re/re-avd.sh frida-stop

# Check if server is running on device
adb shell "su 0 sh -c 'ps -A | grep frida'"

# Check server log
adb shell "su 0 sh -c 'tail -20 /data/local/tmp/frida.log'"
```

### Listing processes

```bash
# List all processes on USB device
frida-ps -U

# List only applications (not system services)
frida-ps -Ua

# Find a specific package
frida-ps -U | grep com.example.target
```

### Attaching and running inline scripts

```bash
# Attach by name (interactive REPL)
frida -U -n com.example.target

# Attach by PID
frida -U -p 1234

# Run a one-shot script (non-interactive, exits after script runs)
# Note: Frida 17.x does NOT have --no-pause. Use -q for quiet mode.
frida -U -n com.example.target -q -e 'console.log("attached")'

# Load a script file
frida -U -n com.example.target -l /tmp/hook.js -q
```

### Useful inline hooks

```bash
# Read Build fields (check what the app sees)
frida -U -n com.example.target -q -e '
var B = Java.use("android.os.Build");
console.log("MODEL=" + B.MODEL.value);
console.log("HARDWARE=" + B.HARDWARE.value);
console.log("MANUFACTURER=" + B.MANUFACTURER.value);
console.log("BRAND=" + B.BRAND.value);
console.log("DEVICE=" + B.DEVICE.value);
console.log("FINGERPRINT=" + B.FINGERPRINT.value);
'

# Hook URL connections to log all HTTP requests from Java
frida -U -n com.example.target -q -e '
Java.perform(function() {
  var URL = Java.use("java.net.URL");
  URL.$init.overload("java.lang.String").implementation = function(url) {
    console.log("[URL] " + url);
    return this.$init(url);
  };
});
'

# Hook SharedPreferences to see what the app stores
frida -U -n com.example.target -q -e '
Java.perform(function() {
  var SP = Java.use("android.app.SharedPreferencesImpl");
  SP.getString.implementation = function(key, defValue) {
    var result = this.getString(key, defValue);
    console.log("[SP] " + key + " = " + result);
    return result;
  };
});
'

# Bypass basic root check (File.exists)
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

### Using Frida in the tmux frida pane

For long-running hooks, send Frida commands to the tmux frida pane instead of running them inline:

```bash
# Clear and start a Frida session in the frida pane
tmux send-keys -t android-re:frida C-c
tmux send-keys -t android-re:frida "frida -U -n com.example.target" Enter

# Wait for attach, then send hook commands
sleep 3
tmux send-keys -t android-re:frida 'Java.perform(function(){ console.log("hooks loaded"); })' Enter

# Read the output
tmux capture-pane -t android-re:frida -p -S -40
```

### Attach failures

If `frida -U -n <name>` fails:

```bash
# Try by PID instead
frida-ps -U | grep com.example.target
frida -U -p <pid>

# Try with emulated realm (for translated ARM code)
frida -U -n com.example.target --realm=emulated

# Try spawn mode (starts the app fresh with Frida injected)
frida -U -f com.example.target
```

---

## agent-device — Practical Usage Guide

### Always load the skill first

The `agent-device` skill provides the canonical command reference. Load it before any UI interaction.

### Core workflow

```bash
# 1. List devices
agent-device devices --platform android

# 2. Open an app
agent-device open com.example.target --platform android

# 3. Take a snapshot to get interactive elements with stable refs
agent-device snapshot -i
# Output includes @eN refs like:
#   [e3] button "Login"
#   [e5] textfield "Email"
#   [e7] textfield "Password"

# 4. Interact using refs (always re-snapshot after UI changes)
agent-device click @e3
agent-device fill @e5 "user@example.com"
agent-device find "Settings" click

# 5. Take a screenshot to verify state
agent-device screenshot --out /tmp/screen.png

# 6. Close when done
agent-device close
```

### Key rules

- Always `snapshot -i` before interacting — refs invalidate on any UI change
- Prefer refs (`@eN`) over raw coordinates
- Use `find "label" click` for semantic element lookup
- `agent-device` does NOT replace `adb` for low-level tasks (push/pull, shell, root, logcat, port-forward)
- iOS (`--platform ios`) is not available on this Linux host

---

## adb — Quick Reference

```bash
# Device management
adb devices -l
adb shell getprop sys.boot_completed

# App management
adb install -r /path/to/app.apk
adb shell pm list packages | grep example
adb shell pm path com.example.target
adb shell am force-stop com.example.target
adb shell monkey -p com.example.target -c android.intent.category.LAUNCHER 1
adb shell dumpsys package com.example.target | grep versionName
adb shell pidof com.example.target

# Root commands
adb shell 'su 0 sh -c id'
adb shell 'su 0 setenforce 0'          # SELinux permissive
adb shell getenforce

# File operations
adb push local.txt /data/local/tmp/
adb pull /data/local/tmp/file.txt ./
adb shell "su 0 sh -c 'ls /data/data/com.example.target/'"

# Port forwarding
adb forward tcp:8080 tcp:8080

# Screenshots
adb shell screencap -p /data/local/tmp/screen.png
adb pull /data/local/tmp/screen.png /tmp/screen.png
```

---

## Device Spoofing

- Applied automatically on `re-avd.sh start` via `RE_SPOOF_DEVICE=1`
- Spoofs 45+ system properties, hides emulator files, stops emulator services
- Re-apply manually: `bash scripts/ai/android-re/re-avd.sh spoof`
- Restore hidden files: `bash scripts/ai/android-re/re-avd.sh unspoof`
- Props need emulator reboot to fully revert
- **Limitation**: `resetprop` changes are visible to `getprop` but `android.os.Build.*` Java fields are cached by Zygote. Apps checking `Build.MODEL` in Java may still see emulator values. Use the Frida spoof script to override at Java level:

```bash
# Run the Build spoof script on a target app
frida -U -f com.example.target -l scripts/ai/android-re/frida-spoof-build.js --no-pause

# Or attach to a running app
frida -U -n com.example.target -l scripts/ai/android-re/frida-spoof-build.js
```

---

## Not Currently Available In PATH

- `dex2jar`

## Recommended Additions

### High value

1. `dex2jar` — alternate DEX conversion path when JADX output is awkward or partial.

### Nice to have

1. `mobsf` — broad static triage and reporting
2. `rizin` — alternative native analysis
3. `burpsuite` — second interception path

---

## Important Constraints

- Google emulator ARM64 AVD boot is not supported on this `x86_64` Linux host
- HTTPS interception works for non-Google domains; Google domains are certificate-pinned by Chrome
- Proxy is opt-in by default — use `proxy-set` to enable, `proxy-clear` to disable
- Some ARM-only apps may run via translation on `google_apis/x86_64` but not equivalent to native ARM guest
