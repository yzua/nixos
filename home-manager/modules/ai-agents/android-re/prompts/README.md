# Android RE Workspace

This directory is the editable instruction and workflow source for Android
reverse engineering on this machine.

The Markdown files here are injected into the `android-re` OpenCode agent. Keep
operational guidance here, not hardcoded in shell wrappers.

## What This Workspace Is For

Use this workspace when you need to:

- triage an APK or installed package
- map endpoints, auth flows, or network protocols
- verify whether traffic can be intercepted
- locate root, emulator, Frida, or pinning defenses
- build Frida hooks or small POC scripts
- diagnose why proxying, root, spoofing, or instrumentation is failing

This workspace is not for broad exploit development without target evidence.
The expectation is: prove each step, then escalate.

## What "Good Hacker" Means Here

In this workspace, "good hacker" means:

- thinks adversarially but stays evidence-driven
- hunts for real vulnerabilities, not just indicators
- understands Android trust boundaries
- can pivot between static, network, runtime, and native layers
- prefers small proofs that demonstrate impact
- avoids getting stuck on anti-analysis theater with no security outcome

The strongest outputs are not giant notes dumps. They are compact findings such
as:

- an exported component that can be abused cross-app
- a replayable authenticated request that bypasses intended checks
- a WebView bridge or deep link issue with reachable impact
- a local token or secret exposure that changes attacker capability
- a pinning or crypto flaw that exposes meaningful sensitive traffic or trust
  failure

## Current Baseline

- Emulator: `re-pixel7-api34`
- Device profile: Pixel 7
- Android: 14 / API 34
- Image: `google_apis/x86_64`
- Root: Magisk with unattended `shell` policy
- Graphics on Linux: host GPU path via NVIDIA Vulkan ICD
- Working HTTPS interception: custom CA on `mitmdump` port `8084`
- Frida: system `17.5.1` toolchain with matching server
- Device spoofing: automatic on `start` via Pixel 7 profile
- UI automation: `agent-device` for structured accessibility-tree interaction
- Host limitation: native ARM64 AVD boot is not supported on this `x86_64`
  Linux host with the current emulator backend
- iOS limitation: `agent-device --platform ios` is unavailable on this Linux
  host and requires macOS + Xcode

## Prompt Source Layout

- `AGENTS.md`: strict session contract and default assumptions
- `WORKFLOW.md`: phased RE workflow and pivot logic
- `TOOLS.md`: task-oriented command recipes and tool guidance
- `TROUBLESHOOTING.md`: symptom-driven failure recovery

Operator-owned scripts stay outside this prompt bundle:

- `scripts/ai/android-re/re-avd.sh`: emulator and dynamic-analysis helper
- `scripts/ai/android-re/re-static.sh`: static-analysis helper

## Fast Start

### 1. Verify the environment

```bash
bash scripts/ai/android-re/re-avd.sh doctor
bash scripts/ai/android-re/re-avd.sh status
```

### 2. Start the emulator if needed

```bash
bash scripts/ai/android-re/re-avd.sh start
tail -f ~/Downloads/android-re-tools/re-avd-start.log
```

### 3. Choose the right launcher

- `ocare` — balanced general triage
- `ocgptare` — protocol/auth mapping and deeper structured execution
- `ocglmare` — anti-analysis, pinning, and cost-effective repeated probing
- `oczenare` — static-first reconnaissance and low-cost wide searches

Examples:

```bash
ocare "prepare the emulator and inspect this target"
ocgptare "focus on auth, traffic, and replay surfaces"
ocglmare "look for root, emulator, and anti-Frida paths"
oczenare "do static APK triage and summarize likely pivots"
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

- boots the emulator in the background via `scripts/ai/android-re/re-avd.sh start`
- writes boot logs to `~/Downloads/android-re-tools/re-avd-start.log`
- builds prompt context from every root-level Markdown file in this directory
- opens Ghostty running OpenCode on the `android-re` agent

The agent should still verify readiness with `status` or `adb wait-for-device`
before dynamic work.

## Decision Guide

Start every target by answering these questions in order:

1. **Can the baseline boot and root cleanly?**
2. **What is the target package, version, and ABI?**
3. **Can the app install and launch without instrumentation?**
4. **What network stack does static triage suggest?**
5. **Can explicit proxy capture any traffic?**
6. **Does failure look like pinning, proxy bypass, native TLS, or app crash?**
7. **Is Frida attach/spawn usable on this process?**
8. **What is the next smallest proof step?**

If you cannot answer a question with evidence, stay in the current phase.

## Vulnerability-First Heuristics

When choosing what to investigate next, prefer this order:

1. can I reach an auth or authz boundary?
2. can I abuse an exported component or deep link?
3. can I extract secrets, tokens, or sensitive local data?
4. can I map the app's real network trust model?
5. can I prove a replay, IDOR, or weak binding issue from captured traffic?
6. do I need Frida or anti-analysis bypass to reach one of those outcomes?

This keeps the agent focused on real vulnerability work instead of endless setup.

## What "Ready" Means

Before dynamic RE, the baseline is considered ready only if all are true:

- AVD exists and is online in `adb devices`
- `sys.boot_completed=1`
- `adb shell 'su 0 sh -c id'` works
- proxy state is known (`8084` or intentionally disabled)
- Frida server status is known
- you know where to read tmux panes: `mitm`, `frida`, `logs`, `logcat`

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
agent-device find "Network" click
agent-device screenshot --out /tmp/screen.png
agent-device close
```

Device spoofing:

```bash
bash scripts/ai/android-re/re-avd.sh spoof
bash scripts/ai/android-re/re-avd.sh unspoof
```

## Static Output Default

`re-static.sh` writes extracted APK output to:

```text
~/.cache/android-re/out
```

Override with `OUTPUT_ROOT=/path/to/out` when you want a custom location.

## Architecture Notes

This workspace is designed around a rooted `x86_64` AVD because that is the
stable path on this machine.

Confirmed host constraint:

```text
Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.
```

Implication:

- use the rooted `x86_64` AVD as the default RE device on this host
- if a target app is ARM-only, it may rely on translation on `google_apis/x86_64`
- translation can be good enough for many tasks but should not be mistaken for
  a native ARM guest

## Editing Rules For This Prompt Bundle

- Put reusable baseline guidance here
- Keep target-specific exploit logic in temporary scripts or a target-specific
  workspace
- Prefer exact commands, expected outputs, and pivot rules over narrative text
- When guidance changes because the machine changed, update the prompt files
  instead of burying facts in wrapper scripts
