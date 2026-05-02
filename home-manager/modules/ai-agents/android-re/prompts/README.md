# Android RE Workspace

This directory is the editable instruction and workflow source for Android
reverse engineering on this machine.

The Markdown files here are injected into the `android-re` OpenCode agent. Keep
operational guidance here, not hardcoded in shell wrappers.

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

- `AGENTS.md`: session contract, priorities, workflow rules, evidence templates
- `CODEQL-GUIDE.md`: CodeQL setup, database creation, and custom Android queries
- `DATAFLOW-VALIDATION.md`: 5-step source-to-sink validation framework
- `EXPLOIT-METHODOLOGY.md`: structured PoC development with per-vuln strategies
- `FINDINGS-PRIORITIZATION.md`: adversarial priority order and severity adjudication
- `NATIVE-FUZZING.md`: AFL++ fuzzing, corpus generation, and crash analysis
- `SEMGREP-GUIDE.md`: Semgrep setup and custom Android rules
- `SESSION-MEMORY.md`: persistent learning across sessions with confidence scoring
- `TOOLS.md`: task-oriented command recipes and tool guidance
- `TROUBLESHOOTING.md`: symptom-driven failure recovery
- `WORKFLOW.md`: phased static and dynamic RE workflow with pivot logic

Operator-owned scripts stay outside this prompt bundle:

- `scripts/ai/android-re/re-avd.sh`: emulator and dynamic-analysis helper
- `scripts/ai/android-re/re-static.sh`: static-analysis helper (includes `diff`
  for version comparison)
- `scripts/ai/android-re/workspace-init.sh`: target workspace initialization

## Target Workspace Convention

All target-specific work goes in `~/Documents/{app-name}/`. This directory
persists across sessions and carries findings, notes, evidence, and PoC scripts
between agent sessions.

Initialize a new target workspace:

```bash
bash scripts/ai/android-re/workspace-init.sh init com.example.target /path/to/app.apk
```

The workspace contains OWASP-aligned templates for findings (M1–M10), endpoints,
anti-analysis defenses, exported components, attack surface maps, and session
history. See `AGENTS.md` for the full workspace convention and rules.

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

Full assessment example:

```bash
ocare "full assessment of com.example.target at ~/Documents/mythingapp: \
read the dir to learn context from previous sessions, then do \
complete static + dynamic analysis, test all UI screens and features, \
find vulnerabilities and bugs, document everything in the workspace, \
put all scripts/hooks/PoC there, spawn subagents for parallel work"
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

## Launcher Bias Guide

Use the launcher that best fits the current branch, then switch once evidence
points elsewhere:

- `oczenare` -> cheapest static-first APK reconnaissance and wide search
- `ocgptare` -> structured auth, protocol, replay, and reporting work
- `ocglmare` -> anti-analysis, pinning, and repeated bypass tries
- `ocare` -> balanced default when the target is not yet classified

## Vulnerability-First Heuristics

When choosing what to investigate next, prefer this order:

1. can I reach an auth or authz boundary?
2. can I abuse an exported component or deep link?
3. can I extract secrets, tokens, or sensitive local data?
4. can I map the app's real network trust model?
5. can I prove a replay, IDOR, or weak binding issue from captured traffic?
6. do I need Frida or anti-analysis bypass to reach one of those outcomes?

## Manual Commands

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
bash scripts/ai/android-re/re-static.sh diff old_version new_version
```

Target workspace:

```bash
bash scripts/ai/android-re/workspace-init.sh init com.example.target /path/to/app.apk
```

Proxy and Frida:

```bash
bash scripts/ai/android-re/re-avd.sh proxy-set 10.0.2.2:8084 --block-quic
bash scripts/ai/android-re/re-avd.sh proxy-clear
bash scripts/ai/android-re/re-avd.sh frida-start
bash scripts/ai/android-re/re-avd.sh frida-stop
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
