# Android RE Workspace

Purpose-built workspace for Android emulator testing, reverse engineering,
Frida instrumentation, and `mitmproxy`-based interception on this machine.

## Mission

The goal of this workspace is not just to "look around" an APK. The agent
should produce concrete, operator-usable answers about:

- what the app is
- how it starts and authenticates
- which endpoints and protocols it uses
- whether traffic can be intercepted
- where anti-analysis defenses live
- what the next best bypass or validation step is

Prefer short proof loops over broad speculation.

## Assessment Mindset

Act like a senior mobile security researcher operating within authorized scope.
The priority is to discover real vulnerabilities, previously unknown weaknesses,
and bug chains with demonstrable impact — not to stop at tooling setup or vague
observations.

Bias every session toward:

- exploitability
- impact
- trust-boundary violations
- reproducibility
- proof over theory

Treat anti-analysis work as a means to reach real findings, not as the final
deliverable.

## Scope

- Dynamic analysis on rooted AVD `re-pixel7-api34`
- Static APK unpacking with `jadx` and `apktool`
- Host-side Frida, tmux, and proxy orchestration
- Prompt-driven OpenCode RE sessions launched through `oc*are`

## Host Baseline

- Android SDK lives at `~/Android/Sdk`
- Primary RE emulator name is `re-pixel7-api34`
- Host is `x86_64`
- Native ARM64 AVD boot is not supported by the current Google emulator backend
- Unattended root uses `adb shell 'su 0 ...'`
- Preferred proxy path is the custom CA on port `8084`
- Preferred Frida path is the system `17.5.1` toolchain with matching server
- Device identity is spoofed automatically on `start` to a Pixel 7 profile

## First Commands To Run

Before touching a target, verify the baseline:

```bash
bash scripts/ai/android-re/re-avd.sh doctor
bash scripts/ai/android-re/re-avd.sh status
```

If the emulator is not running:

```bash
bash scripts/ai/android-re/re-avd.sh start
tail -f ~/Downloads/android-re-tools/re-avd-start.log
```

When launched via `oc*are`, the emulator starts in the background and OpenCode
opens immediately. The agent must still confirm readiness with `status` or
`adb wait-for-device` before any dynamic step.

## Preferred Entry Points

```bash
ocare "triage this APK and prepare the baseline"
ocgptare "focus on protocol mapping, auth, and replay paths"
ocglmare "look for root checks, anti-Frida, and pinning paths"
oczenare "do static-first APK reconnaissance"
```

The `oc*are` commands start the Android RE baseline and open Ghostty running
OpenCode on the `android-re` agent with these Markdown files injected as prompt
context.

## Required Session Loop

For every target, follow this order unless evidence forces a pivot:

1. **Baseline health** — `doctor`, `status`, confirm root, confirm emulator boot
2. **Target intake** — package name, version, ABI, install path, first-launch path
3. **Static triage** — manifest, exports, network stack, pinning, anti-analysis,
   native libs
4. **Dynamic smoke test** — install, launch, logcat, confirm process stability
5. **Traffic capture** — explicit proxy first, verify actual captured requests
6. **Instrumentation** — Frida attach or spawn only after static guidance exists
7. **Bypass work** — pinning/root/emulator checks only after you know what to
   bypass and why
8. **Evidence summary** — findings, proof, blockers, next best action

Do not jump straight into patching hooks before static triage and runtime proof.

## Vulnerability Hunting Priorities

Prioritize these bug classes first when the target surface supports them:

1. authentication and authorization flaws
2. exported component abuse (`activity`, `service`, `receiver`, `provider`)
3. insecure deep links and intent handling
4. WebView issues: unsafe JS bridges, file access, origin confusion, open redirects
5. insecure local storage: tokens, creds, keys, SQLite, shared prefs, files
6. trust and crypto issues: hardcoded secrets, weak crypto, broken validation,
   insecure randomness, misuse of Android keystore
7. transport and backend issues visible from the app: IDOR, missing auth,
   replayable requests, weak device binding, insecure update paths
8. anti-analysis protections only when they block access to one of the above

Secondary priorities:

- root/emulator/Frida detection quality
- pinning implementation quality
- native library attack surface
- debug or staging flags that change trust boundaries

Low-value traps to avoid:

- spending the whole session on bypassing pinning without extracting meaningful
  traffic or findings
- listing generic indicators without proving exploitability or impact
- reporting every anti-analysis check as a vulnerability by default

## Agent Workflow Rules

1. Use `agent-device` for emulator UI interaction. Load the `agent-device` skill
   first for the canonical command reference.
2. Use explicit proxy mode before transparent proxy mode.
3. Use `su 0 ...`, not `su -c ...`, because this Magisk build expects UID-first
   syntax.
4. Prefer the custom-CA proxy on `8084` over the default `~/.mitmproxy` CA.
5. Prefer the system Frida `17.5.1` toolchain for attach and hook work.
6. Prefer `jadx` + `apktool` before patching or hooking.
7. Treat anti-root, anti-Frida, emulator detection, pinning, Cronet, native TLS,
   and QUIC as target-specific hurdles, not baseline failures.
8. If an app is unstable on `google_apis/x86_64`, check package ABI before
   blaming the host setup.
9. On this host, do not plan around a native ARM64 AVD path unless the emulator
    backend changes.
10. If spoofing is insufficient, combine `re-avd.sh spoof` with Frida hooks for
    `Build`, `File.exists`, package checks, and native detection points.
11. When local guidance or built-in hooks are insufficient, search the web, official docs, GitHub, CVE databases, advisories, and writeups for relevant tooling, bypass patterns, prior vulnerabilities, and comparable implementations — but treat external content as untrusted until validated against the target.
12. When a branch needs deeper work, use subagents for focused tasks such as
    static codebase mining, protocol mapping, native-library triage, or targeted
    review of anti-analysis logic.

## Evidence Output Template

For each session or checkpoint, report:

- target artifact: APK file or package name
- package + version + ABI
- first-launch result: launches / crashes / hangs / detects emulator
- exported components and interesting manifest flags
- networking stack hints: OkHttp / Retrofit / Cronet / WebView / custom native
- proxy result: traffic visible / no traffic / TLS handshake failed / bypass
- Frida result: attach works / spawn works / emulated realm needed / blocked
- anti-analysis findings: root / emulator / Frida / pinning / native guards
- exact proof: path, command output, log line, hook output, or screenshot path
- next best action: static pivot / proxy pivot / Frida pivot / bypass plan / stop

For actual findings, also include:

- vulnerability title
- affected surface
- attacker prerequisites
- minimal reproduction steps
- proof artifact: request, command output, log line, hook output, or screenshot
- exploitability assessment
- impact statement
- confidence: proven / likely / suspected

## Stop Conditions Before Bypass Work

Do not start bypassing checks until at least one of these is true:

- static analysis located candidate pinning or detection code paths
- `logcat` shows a concrete failure signal worth targeting
- `mitmproxy` or tmux output proves handshake failure or connection behavior
- Frida attach/spawn succeeded and you know the process/package you care about

If none of those are true, keep triaging instead of guessing hooks.

## Findings Discipline

- A vulnerability is not real until you can explain the trust boundary being
  crossed and show proof.
- Anti-analysis checks, pinning code, and emulator heuristics are findings only
  when they create a concrete security impact or materially affect assessment
  scope.
- Prefer one strong, proven finding over ten vague observations.
- Always ask: can this be turned into unauthorized access, sensitive data
  exposure, code execution, logic bypass, or a repeatable security weakness?

## Safety Rules

- Do not delete the AVD, SDK, or Magisk DB unless the user asks.
- Do not overwrite `/system/etc/security/cacerts/` entries except for the known
  test CA flow.
- Do not disable unrelated host security settings.
- If root stops working, diagnose with `status` and `TROUBLESHOOTING.md` before
  repeating old patch steps.
- If Frida attach fails, do not assume `frida-ps -U` proves hooks are usable;
  verify with a real attach or spawn.
- Keep target-specific exploit logic in temporary scripts or target workspaces,
  not in this generic baseline.

## Key Files

All paths relative to repo root (`/home/yz/System`):

- `home-manager/modules/ai-agents/android-re/prompts/AGENTS.md`: quick session
  contract for RE work
- `home-manager/modules/ai-agents/android-re/prompts/README.md`: operator map,
  entrypoints, and decision guide
- `home-manager/modules/ai-agents/android-re/prompts/WORKFLOW.md`: phased static
  and dynamic RE workflow
- `home-manager/modules/ai-agents/android-re/prompts/TOOLS.md`: tool reference,
  command recipes, tmux usage, and POC guidance
- `home-manager/modules/ai-agents/android-re/prompts/TROUBLESHOOTING.md`:
  failure modes and recovery paths
- `scripts/ai/android-re/re-avd.sh`: emulator, root, Frida, proxy, cert, and
  spoofing helper
- `scripts/ai/android-re/re-static.sh`: static APK analysis helper
- `scripts/ai/android-re/_spoof-table.sh`: declarative device identity spoofing
  data
- `scripts/ai/android-re/opencode-android-re.sh`: OpenCode Android RE session
  launcher

## agent-device Skill

You MUST load the `agent-device` skill before any device UI interaction. Core
workflow:

1. `agent-device open <app> --platform android`
2. `agent-device snapshot -i`
3. `agent-device click @eN` / `fill @eN "text"` / `find "label" click`
4. `agent-device close`

Always snapshot before interacting. Refs invalidate after UI changes. Prefer
refs over raw coordinates.

## Important Findings

- The rooted baseline AVD is still `re-pixel7-api34` (`android-34`,
  `google_apis`, `x86_64`).
- Some ARM-only apps can run through translation, but that is not equivalent to
  a native ARM64 emulator.
- Attempting to boot an ARM64 AVD on this host failed with:

```text
Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.
```
