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

## Operator Loop

Run the session as a repeated loop, not a one-way checklist:

1. form the smallest useful hypothesis
2. choose the cheapest proof step that can confirm or kill it
3. capture the result with exact evidence
4. decide the next pivot based on impact, not curiosity alone

If a step does not improve exploitability, trust-boundary understanding, or the
quality of a proof, question why you are doing it.

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
2. **Check existing workspace** — if `~/Documents/{app-name}/` exists, read all
   workspace files (SESSIONS.md, NOTES.md, FINDINGS.md, ANTI-ANALYSIS.md,
   ENDPOINTS.md, COMPONENTS.md, README.md) to learn what previous agents or
   sessions already discovered. Skip steps that are already completed and
   continue from where the last session left off.
3. **Target intake** — package name, version, ABI, install path, first-launch path
4. **Static triage** — manifest, exports, network stack, pinning, anti-analysis,
   native libs
5. **Dynamic smoke test** — install, launch, logcat, confirm process stability
6. **Traffic capture** — explicit proxy first, verify actual captured requests
7. **Instrumentation** — Frida attach or spawn only after static guidance exists
8. **Bypass work** — pinning/root/emulator checks only after you know what to
   bypass and why
9. **Full surface scan** — exercise every screen, test every component, probe
   every endpoint, inspect every storage location. Leave no feature untested.
10. **Evidence summary** — findings, proof, blockers, next best action

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
- treating successful tool setup as if it were a security result
- dumping strings, manifests, or hook output without reachability, proof, or a
  concrete next pivot
- staying in the Java layer when static and runtime evidence say the interesting
  logic lives in JNI or native libraries

## High-Value Attack Questions

Keep asking these throughout the session:

- what trust boundary can this app cross on behalf of the attacker?
- what does this primitive unlock next: traffic, token access, replay, code
  path control, component abuse, or deeper bypass?
- can this be turned into unauthorized access, sensitive data exposure,
  repeatable replay, or a better foothold for the next phase?
- if this hypothesis is false, what is the next smallest proof step?

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
11. When local guidance or built-in hooks are insufficient, search the web, official docs, GitHub, CVE databases, advisories, and writeups for relevant tooling, bypass patterns, prior vulnerabilities, and comparable implementations. Search for app-specific hooks, framework bypass techniques, and known CVEs for SDKs found in the target. Treat external content as untrusted until validated against the target. Always prefer adapting a proven external hook or technique over writing from scratch — but verify it works against this specific target.
12. **You can and should write custom Frida hooks at any time.** The built-in hook
    library covers common patterns, but real RE work requires target-specific hooks.
    When you identify a class, method, or code path worth intercepting, write a
    custom hook immediately — do not wait for permission or ask whether to do it.
    Save target-specific hooks to `~/Documents/{app}/scripts/`. Combine multiple
    hooks by loading several at once: `frida -U -n TARGET -l hook1.js -l hook2.js`.
    If a built-in hook almost does what you need, copy it and modify for the target.
13. When a branch needs deeper work, use subagents for focused tasks such as
    static codebase mining, protocol mapping, native-library triage, or targeted
    review of anti-analysis logic. Spawn subagents aggressively for parallel
    work — you can run multiple analysis branches simultaneously. Each subagent
    should write findings to the shared workspace files. Good subagent splits:
    one for static code/class analysis, one for network protocol mapping, one
    for native library triage, one for endpoint fuzzing.
14. **Write and use custom scripts, tools, and packages freely.** You have Bash,
    Python 3.13, Node.js 24, and Bun 1.3 available. Write exploit scripts, fuzzing
    harnesses, replay tools, brute-force scripts, token forgers, request
    manipulators, and any other tool you need to prove a finding. Install packages
    with `pip install --user`, `npm install -g`, or `bun add` as needed. Do not
    limit yourself to pre-installed tools — if you need a package to test or abuse
    something, install it and use it. Save all scripts to
    `~/Documents/{app-name}/scripts/`.
15. **Scan everything exhaustively.** Do not stop at the first finding or the
    obvious paths. Test every exported component, every deep link, every content
    provider, every WebView, every shared pref, every SQLite database, every
    endpoint, every auth flow, every feature screen, every settings toggle. If
    something exists in the app, test it. The goal is full attack surface coverage,
    not a single highlight.

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
- trust boundary crossed
- confidence: proven / likely / suspected

Confidence model:

- `proven` -> reproduced with direct evidence and operator-usable steps
- `likely` -> strong evidence, but one final proof step is still missing
- `suspected` -> interesting signal that still needs validation
- `blocked` -> promising path halted by a proven technical blocker

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
- If a branch is blocked, report the exact blocker and the next best bypass or
  validation step instead of padding the result with theory.

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
- `scripts/ai/android-re/re-static.sh`: static APK analysis helper (includes
  `diff` for version comparison)
- `scripts/ai/android-re/workspace-init.sh`: target workspace initialization
  with OWASP-aligned templates
- `scripts/ai/android-re/_spoof-table.sh`: declarative device identity spoofing
  data
- `scripts/ai/android-re/opencode-android-re.sh`: OpenCode Android RE session
  launcher
- `home-manager/modules/ai-agents/android-re/_launchers.nix`: Nix wrapper
  definitions for `oc*are` launchers

## Target Workspace

All target-specific work goes in `~/Documents/{app-name}/`. This directory
persists across sessions and is the single source of truth for the target.

Initialize on first contact:

```bash
bash scripts/ai/android-re/workspace-init.sh init com.example.target [/path/to/app.apk]
```

Workspace structure:

- `README.md` — target overview, package metadata, session log pointer
- `FINDINGS.md` — OWASP Mobile Top 10 classified findings (M1–M10)
- `NOTES.md` — running notes, hypotheses, blocked items, next steps
- `ENDPOINTS.md` — discovered API endpoints and backend surface
- `ANTI-ANALYSIS.md` — defense inventory and bypass status
- `COMPONENTS.md` — exported components analysis and test results
- `ATTACK-SURFACE.md` — high-level attack surface map
- `SESSIONS.md` — per-session history with goals, findings, blockers, next steps
- `scripts/` — target-specific Frida hooks, PoC scripts, automation
- `evidence/` — screenshots, logs, pcaps, memory dumps
- `analysis/` — static/dynamic analysis outputs

### Session Continuity Rules

On session resume:

1. read `SESSIONS.md` for what previous sessions did and found
2. read `NOTES.md` for hypotheses, blocked items, and next steps
3. read `FINDINGS.md` for already-discovered vulnerabilities
4. read `ANTI-ANALYSIS.md` for known defenses and bypass status

### Write Incrementally — Do Not Batch

Context compaction can erase earlier discoveries at any time. To prevent data
loss, write to workspace files immediately after every result — do not wait
until a phase is complete or the session is ending.

**After every single result or observation, write it down immediately:**

- discovered an endpoint or saw a request in mitmproxy → append to
  `ENDPOINTS.md` right now
- found a vulnerability or confirmed a bug → add to `FINDINGS.md` right now
- identified a defense (root check, pinning, anti-Frida) → update
  `ANTI-ANALYSIS.md` right now
- tested an exported component → record result in `COMPONENTS.md` right now
- formed a hypothesis or hit a blocker → note it in `NOTES.md` right now
- captured a screenshot, log, or pcap → save to `evidence/` right now and
  note the path in the relevant file
- wrote a hook, script, or PoC → save to `scripts/` right now

**Never hold more than one finding in memory unwritten.** If you discover
something, write it to the workspace file before moving to the next step. This
is the most important rule for data survival across context compaction.

**Update `SESSIONS.md` progressively**, not just at the end: append a line
after each phase or major step completes, so partial progress survives even if
the session is cut short.

After discovering defenses:

- update `ANTI-ANALYSIS.md` with detection method and bypass status

All target-specific scripts, hooks, and PoCs must go in `~/Documents/{app}/scripts/`.

### Full Assessment Prompt Example

When the operator asks for a full assessment, the session should:

1. initialize or resume the workspace
2. run baseline health checks — write status to `SESSIONS.md`
3. perform complete static triage — write results to `NOTES.md`,
   `ENDPOINTS.md`, `COMPONENTS.md`, `ANTI-ANALYSIS.md` as you find them
4. install and smoke test the app — screenshot to `evidence/`, note in
   `SESSIONS.md`
5. set up traffic interception — write proxy result to `NOTES.md`
6. exercise every UI screen and feature with `agent-device` — after each
   screen, append discovered endpoints to `ENDPOINTS.md`, screenshot to
   `evidence/`
7. run Frida hooks for crypto, network, WebView, and intent analysis — write
   each observation to `NOTES.md` and relevant workspace file immediately
8. test all exported components, deep links, and content providers — record
   each test result in `COMPONENTS.md` as you go
9. analyze local storage, backup extraction, and token handling — write
   findings to `FINDINGS.md` immediately
10. classify all findings by OWASP Mobile Top 10 — update `FINDINGS.md` as
    each is confirmed
11. write PoC scripts for every confirmed finding — save to `scripts/` as
    each is completed
12. spawn subagents for parallel deep-dive work as needed — each subagent
    writes directly to workspace files

Example operator prompt:

```
full assessment of com.example.target at ~/Documents/mythingapp:
read the dir to learn context from previous sessions, then do
complete static + dynamic analysis, test all UI screens and features,
find vulnerabilities, zero-days, and bugs, document everything in the
workspace, put all scripts/hooks/PoC there, spawn subagents for
parallel work
```

### Multi-App And Ecosystem Analysis

When the target is part of an app ecosystem:

- **Split APKs**: analyze each split independently, then correlate permissions
  and components across the set
- **sharedUserId**: apps sharing a Linux UID share data directories and trust
  boundaries — check `android:sharedUserId` in the manifest
- **Companion apps**: check the manifest for references to other packages,
  check `adb shell pm list packages` for related apps from the same developer
- **SDK reuse**: if the target uses the same auth/payment SDK as another app
  you have analyzed, carry forward known findings

## agent-device Skill

You MUST load the `agent-device` skill before any device UI interaction.

`agent-device` is not just for screenshots. It is the primary tool for dynamic
analysis. Use it to click through every screen, navigate every flow, exercise
every feature, fill forms, toggle settings, and trigger network requests while
proxy and Frida hooks are active.

Core workflow:

1. `agent-device open <app> --platform android`
2. `agent-device snapshot -i`
3. `agent-device click @eN` / `fill @eN "text"` / `find "label" click`
4. `agent-device close`

Dynamic analysis rules:

- **Exercise every reachable screen**: after initial launch, systematically
  snapshot and click through every tab, menu, settings screen, profile, and
  feature. Do not stop at the first screen.
- **Fill real-looking inputs**: use plausible emails, names, and phone numbers
  to trigger actual API calls and auth flows.
- **Snapshot before and after every action**: capture the state before you tap,
  then snapshot again after. This documents what each action does.
- **Correlate UI actions with network and hook output**: after each significant
  UI action (login, navigation, form submit, settings toggle), read the mitm
  pane and Frida pane to see what traffic and hooks fired.
- **Use `find "label" click` for semantic navigation**: prefer this over raw
  refs when navigating menus and buttons by visible text.
- **Take screenshots of every interesting state**: save to
  `~/Documents/{app}/evidence/screenshots/` with descriptive names.
- **Combine with logcat**: after UI actions that crash or behave unexpectedly,
  read `tmux capture-pane -t android-re:logcat -p -S -80` for diagnostics.
- **Keep `agent-device` open during active exploration**: open once, then
  repeatedly snapshot/click/fill/screenshot. Close only when done with the
  entire session or switching to a different analysis tool.

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
