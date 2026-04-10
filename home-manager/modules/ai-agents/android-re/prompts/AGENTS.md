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
- Reliable Frida attach uses the isolated `16.4.10` toolchain under `~/Downloads/android-re-tools/frida16410-py311/`
- Reliable HTTPS interception uses the custom CA under `~/Downloads/android-re-tools/custom-ca/`
- This host is `x86_64`, and Google emulator ARM64 AVDs are not runnable here with the current QEMU2 emulator

## First Commands To Run

Before touching an app, run:

```bash
bash scripts/ai/android-re/re-avd.sh doctor
bash scripts/ai/android-re/re-avd.sh start
bash scripts/ai/android-re/re-avd.sh status
```

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
2. Use explicit proxy mode before transparent proxy mode.
3. Use `su 0 ...`, not `su -c ...`, because this Magisk build expects UID-first syntax.
4. Prefer the custom-CA proxy on `8084` over the default `~/.mitmproxy` CA on this Android 14 emulator.
5. Prefer Frida `16.4.10` over the system Frida `17.5.1` tools for attach and hooking.
6. Prefer `jadx` + `apktool` before patching or hooking.
7. Treat anti-root, anti-Frida, and pinning as target-specific hurdles, not emulator setup failures.
8. If an app is unstable on the `google_apis/x86_64` AVD, check package ABI before blaming the host setup.
9. On this host, do not plan around a native ARM64 AVD path unless the emulator backend changes.

## Safety Rules

- Do not delete the AVD, SDK, or Magisk DB unless the user asks.
- Do not overwrite `/system/etc/security/cacerts/` entries except for the known test CA flow.
- Do not disable unrelated security settings on the host.
- If root stops working, diagnose with `status` and `TROUBLESHOOTING.md` before rerunning old patch steps blindly.
- If Frida attach fails, do not assume `frida-ps -U` means hooks are usable; verify with a real attach.

## Key Files

- `home-manager/modules/ai-agents/android-re/prompts/README.md`: operator guide and workflow map
- `home-manager/modules/ai-agents/android-re/prompts/WORKFLOW.md`: detailed static + dynamic RE flow
- `home-manager/modules/ai-agents/android-re/prompts/TOOLS.md`: installed tools, missing tools, and recommendations
- `home-manager/modules/ai-agents/android-re/prompts/TROUBLESHOOTING.md`: failure modes and recovery steps
- `scripts/ai/android-re/re-avd.sh`: emulator, root, Frida, proxy, and cert helper
- `scripts/ai/android-re/re-static.sh`: static APK analysis helper

## Important Findings

- The current rooted baseline AVD is still `re-pixel7-api34` (`android-34`, `google_apis`, `x86_64`).
- Some ARM-only apps can run on that AVD via translation, but that path is not equivalent to a native ARM64 emulator.
- Attempting to boot an ARM64 AVD on this host failed with:
  - `Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.`
