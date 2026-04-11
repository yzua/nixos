# Android RE Workspace

Purpose-built workspace for Android emulator testing, reverse engineering, Frida, and `mitmproxy`-based interception.

## Scope

- Dynamic analysis on the rooted AVD `re-pixel7-api34`
- Static APK unpacking with `jadx` and `apktool`
- Host-side Frida and proxy orchestration
- Prompt-driven OpenCode RE sessions launched through `oc*are`

## Default Assumptions

- Host uses the Android SDK at `~/Android/Sdk`
- Primary RE emulator name is `re-pixel7-api34`
- Unattended root is available with `adb shell 'su 0 ...'`
- Reliable Frida attach uses the system `17.5.1` toolchain (matching server + client under `~/Downloads/android-re-tools/frida/`)
- Reliable HTTPS interception uses the custom CA under `~/Downloads/android-re-tools/custom-ca/`
- This host is `x86_64`, and Google emulator ARM64 AVDs are not runnable here with the current QEMU2 emulator

## First Commands To Run

Before touching an app, verify the RE baseline is up:

```bash
bash scripts/ai/android-re/re-avd.sh status
```

If the emulator is not running, start it:

```bash
bash scripts/ai/android-re/re-avd.sh start
```

Note: when launched via `oc*are` aliases, the emulator starts in the background and OpenCode opens immediately. The agent must verify the emulator is ready with `re-avd.sh status` or `adb wait-for-device` before proceeding with dynamic analysis. Check the boot log at `~/Downloads/android-re-tools/re-avd-start.log`.

Preferred operator entrypoints:

```bash
ocare "triage this APK and prepare the baseline"
ocgptare "focus on protocol mapping"
ocglmare "look for anti-Frida and pinning paths"
oczenare "static-first APK reconnaissance"
```

The `oc*are` commands start the Android RE baseline and open Ghostty running OpenCode on the `android-re` agent with these Markdown files injected as prompt context.

## Agent Workflow

1. Check health first: `doctor`, then `status`.
2. Use `agent-device` for all UI interaction on the emulator — load the `agent-device` skill first for the canonical command reference.
3. Use explicit proxy mode before transparent proxy mode.
4. Use `su 0 ...`, not `su -c ...`, because this Magisk build expects UID-first syntax.
5. Prefer the custom-CA proxy on `8084` over the default `~/.mitmproxy` CA on this Android 14 emulator.
6. Prefer the system Frida `17.5.1` toolchain (matching server + client) for attach and hook work.
7. Prefer `jadx` + `apktool` before patching or hooking.
8. Treat anti-root, anti-Frida, and pinning as target-specific hurdles, not emulator setup failures.
9. If an app is unstable on the `google_apis/x86_64` AVD, check package ABI before blaming the host setup.
10. On this host, do not plan around a native ARM64 AVD path unless the emulator backend changes.
11. Device identity is spoofed automatically on `start` (Pixel 7 profile). If an app still detects the emulator, combine `re-avd.sh spoof` with Frida hooks targeting `Build` fields and file-existence checks.

## Safety Rules

- Do not delete the AVD, SDK, or Magisk DB unless the user asks.
- Do not overwrite `/system/etc/security/cacerts/` entries except for the known test CA flow.
- Do not disable unrelated security settings on the host.
- If root stops working, diagnose with `status` and `TROUBLESHOOTING.md` before rerunning old patch steps blindly.
- If Frida attach fails, do not assume `frida-ps -U` means hooks are usable; verify with a real attach.

## Key Files

All paths relative to repo root (`/home/yz/System`):

- `home-manager/modules/ai-agents/android-re/prompts/AGENTS.md`: this file — quick rules for RE sessions
- `home-manager/modules/ai-agents/android-re/prompts/README.md`: operator guide and workflow map
- `home-manager/modules/ai-agents/android-re/prompts/WORKFLOW.md`: detailed static + dynamic RE flow
- `home-manager/modules/ai-agents/android-re/prompts/TOOLS.md`: tool reference, tmux usage, mitmproxy/Frida practical guides
- `home-manager/modules/ai-agents/android-re/prompts/TROUBLESHOOTING.md`: failure modes and recovery steps
- `scripts/ai/android-re/re-avd.sh`: emulator, root, Frida, proxy, cert, and spoofing helper
- `scripts/ai/android-re/re-static.sh`: static APK analysis helper
- `scripts/ai/android-re/_spoof-table.sh`: declarative device identity spoofing data (Pixel 7 profile)
- `scripts/ai/android-re/opencode-android-re.sh`: OpenCode Android RE session launcher (used by `oc*are` aliases)

## agent-device Skill

You MUST load the `agent-device` skill before any device UI interaction. The skill provides the canonical command reference. Core workflow:

1. `agent-device open <app> --platform android` — launch an app
2. `agent-device snapshot -i` — get interactive elements with stable refs
3. `agent-device click @eN` / `fill @eN "text"` / `find "label" click` — interact
4. `agent-device close` — end session

Always snapshot before interacting — refs invalidate on UI changes. Prefer refs (`@eN`) over raw coordinates.

## Important Findings

- The current rooted baseline AVD is still `re-pixel7-api34` (`android-34`, `google_apis`, `x86_64`).
- Some ARM-only apps can run on that AVD via translation, but that path is not equivalent to a native ARM64 emulator.
- Attempting to boot an ARM64 AVD on this host failed with:
  - `Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.`
