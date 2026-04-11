# Android RE Workspace

This directory is the editable instruction and workflow source for Android reverse engineering on this machine.

The Markdown files here are injected into the `android-re` OpenCode agent. Keep operational guidance here, not hardcoded in shell wrappers.

## Current Baseline

- Emulator: `re-pixel7-api34`
- Device profile: Pixel 7
- Android: 14 / API 34
- Image: `google_apis/x86_64`
- Root: Magisk with unattended `shell` policy
- Graphics on Linux: host GPU path via NVIDIA Vulkan ICD
- Working HTTPS interception: custom CA on `mitmdump` port `8084`
- Frida: use the system `17.5.1` toolchain (matching server at `~/Downloads/android-re-tools/frida/` and system `frida`/`frida-ps`)
- Device spoofing: automatic on `start` — emulator identity masked as real Pixel 7 via `resetprop`
- UI automation: `agent-device` for structured accessibility-tree interaction with stable refs
- Host limitation: native ARM64 AVD boot is not supported by the current Google emulator on this `x86_64` Linux host
- iOS limitation: `agent-device --platform ios` is not available on this Linux host; requires macOS + Xcode

## Prompt Source Layout

- `AGENTS.md`: quick rules for future RE sessions
- `WORKFLOW.md`: end-to-end RE workflow
- `TOOLS.md`: installed tools and recommended additions
- `TROUBLESHOOTING.md`: known issues and recovery

Operator-owned scripts stay outside this prompt bundle:

- `scripts/ai/android-re/re-avd.sh`: emulator and dynamic-analysis helper
- `scripts/ai/android-re/re-static.sh`: static-analysis helper

## Primary Entry Points

Preferred commands:

```bash
ocare "prepare the emulator and inspect this target"
ocgptare "focus on protocol and auth mapping"
ocglmare "look for root or anti-Frida checks"
oczenare "do static APK triage first"
```

Available profile launchers:

- `ocare` -> default `opencode` profile
- `ocglmare` -> `opencode-glm`
- `ocgemare` -> `opencode-gemini`
- `ocgptare` -> `opencode-gpt`
- `ocorare` -> `opencode-openrouter`
- `ocsare` -> `opencode-sonnet`
- `oczenare` -> `opencode-zen`

Each launcher:

- boots the emulator in the background via `scripts/ai/android-re/re-avd.sh start` (non-blocking — the OpenCode session opens immediately while the emulator boots)
- the boot log is at `~/Downloads/android-re-tools/re-avd-start.log`; monitor with `tail -f`
- the agent should verify readiness with `bash scripts/ai/android-re/re-avd.sh status` or `adb wait-for-device` before interacting with the emulator
- builds a prompt from every root-level Markdown file in this directory
- opens Ghostty running OpenCode on the `android-re` agent with the chosen profile

## Focused Manual Commands

Health and boot:

```bash
bash scripts/ai/android-re/re-avd.sh doctor
bash scripts/ai/android-re/re-avd.sh start
bash scripts/ai/android-re/re-avd.sh status
```

Static analysis:

```bash
bash scripts/ai/android-re/re-static.sh prepare /path/to/app.apk
bash scripts/ai/android-re/re-static.sh hashes /path/to/app.apk
bash scripts/ai/android-re/re-static.sh inventory
```

Proxy and Frida:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
bash scripts/ai/android-re/re-avd.sh proxy-clear
bash scripts/ai/android-re/re-avd.sh frida-start
bash scripts/ai/android-re/re-avd.sh frida-stop
```

Device UI automation (load the `agent-device` skill first):

```bash
agent-device open Settings --platform android
agent-device snapshot -i
agent-device click @e3
agent-device find "Network" click
agent-device fill @e5 "user@example.com"
agent-device screenshot --out /tmp/screen.png
agent-device close
```

Device spoofing:

```bash
bash scripts/ai/android-re/re-avd.sh spoof      # re-apply Pixel 7 identity
bash scripts/ai/android-re/re-avd.sh unspoof    # restore hidden emulator files
```

## Static Output Default

`re-static.sh` now writes extracted APK output to:

```text
~/.cache/android-re/out
```

Override with `OUTPUT_ROOT=/path/to/out` when you want a custom location.

## Architecture Notes

This workspace is designed around a rooted `x86_64` AVD because that is the stable path on this machine.

Confirmed host constraint:

```text
Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.
```

Implication:

- use the rooted `x86_64` AVD as the default RE device on this host
- if a target app is ARM-only, it may rely on translation on `google_apis/x86_64`
- translation can be good enough for many tasks but should not be mistaken for a native ARM guest
