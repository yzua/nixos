# Utility Scripts

Repository Bash scripts across `ai/`, `apps/`, `build/`, `hardware/`, `sops/`, `system/`, and `lib/`. `lib/` contains shared sourced helpers such as `logging.sh` and `test-helpers.sh`. All shell scripts are checked by `just lint`.

---

## Directory Map

```
scripts/
├── ai/
│   ├── api-quota/
│   │   ├── api-quota.sh         # Noctalia bar widget entrypoint (orchestration + output)
│   │   ├── api-quota-helpers.sh # Shared formatting/cache/time helper functions
│   │   ├── api-quota-providers.sh # Provider collectors (Z.ai, Claude, Codex)
│   │   └── api-quota-test.sh    # Unit tests for api-quota.sh
│   ├── agent-launcher.sh    # Interactive multi-provider AI agent launcher
│   ├── agent-log-wrapper.sh # Agent command logging wrapper with error split
│   ├── agent-analyze.sh     # Log analyzer CLI (stats/errors/sessions/search/tail/report)
│   ├── agent-patterns.sh    # Error pattern detector across agent logs
│   ├── agent-dashboard.sh   # fzf dashboard wrapper for analyzer commands
│   ├── agent-inventory.sh   # Interactive fzf inventory for AI tools (skills, MCP, agents)
│   ├── skills-sync.sh       # Sync AI agent skills from GitHub to ~/.local/share/skills/
│   └── android-re/
│       ├── re-avd.sh        # Android emulator management (AVD create/start/snapshot)
│       ├── re-avd-test.sh   # Unit tests for re-avd.sh
│       └── re-static.sh     # Android static analysis workflow
├── apps/
│   ├── browser-select.sh    # Browser profile selector (wofi menu)
│   ├── element-desktop-keyring.sh # Element Desktop keyring helper
│   ├── playwright-cli-mcp-wrapper.sh # Playwright CLI MCP server wrapper
│   ├── xdg-open-wrapper.sh  # XDG open wrapper for Wayland
│   └── youtube-mpv.sh       # YouTube URL opener via mpv
├── build/
│   ├── modules-check.sh     # Validates default.nix imports match .nix files on disk
│   ├── modules-check-test.sh # Unit tests for modules-check.sh
│   ├── packages-check.sh    # Checks for duplicate packages and program/module conflicts
│   ├── pre-commit-hook.sh   # Git hook: modules → lint → format → check
│   ├── pre-push-hook.sh     # Git hook: enforces GPG-signed commits
│   └── shellcheck-nix-inline.sh # Lints inline Bash in writeShellScript blocks
├── hardware/
│   └── nvidia-fans.sh       # GPU fan control
├── lib/
│   ├── logging.sh           # Shared logging library (colored output, timestamps)
│   └── test-helpers.sh      # Shared test utilities (assertions, mocking)
├── sops/
│   ├── editor-code-wait.sh  # VS Code wait wrapper for sops editing
│   └── sops-edit.sh         # Secrets editor (RAM-backed tmpfs, age encryption)
├── system/
│   └── report/
│       ├── system-report.sh     # Unified health report (full/errors mode)
│       ├── report-collectors.sh # Compatibility shim loading collector modules
│       ├── report-collectors-core.sh # Core collectors: systemd, timers, network, builds, AI logs
│       ├── report-collectors-observability.sh # Observability collectors: Loki/Netdata/Scrutiny/resource metrics
│       ├── report-collectors-security.sh # Security collectors: fail2ban, Lynis, OpenSnitch, hardening
│       ├── report-helpers.sh    # Report generation helper functions
│       └── report-collectors-test.sh # Unit tests for report collectors
```

---

## Conventions

- **Strict Shebang**: `#!/usr/bin/env bash` followed by `set -euo pipefail`. This is mandatory for all executable scripts to ensure portability and immediate exit on errors or unset variables.
- **Sourced libraries** (`lib/`): Do NOT include `set -euo pipefail` (inherited from caller).
- **Quote all variables**: `"$var"`, `"${array[@]}"`.
- **Conditionals**: `[[ ... ]]` (not `[ ... ]`).
- **Arrays**: `mapfile` for reading from commands.
- **Error handling**: `error_exit "message" code`.
- **Logging**: Source `scripts/lib/logging.sh` — never define `log_info`/`print_info` locally.
- **Unit Testing**: Use the `*-test.sh` suffix for test files, placed in the same directory as the script under test. Run tests frequently.

---

## Shared Logging Library (`lib/logging.sh`)

Source the library using:

```bash
source "$(dirname "$0")/../lib/logging.sh"
```

### Functions

- **Colored Output**: `print_info`, `print_success`, `print_warning`, `print_error`. These use emojis and ANSI colors for terminal visibility.
- **Timestamped Logging**: `log_info`, `log_success`, `log_warning`, `log_error`. These add ISO-style timestamps and log to `stderr` for warnings/errors.

### File Logging

If the `LOG_FILE` environment variable is set, all `log_*` functions will append their output to that file using `tee`, ensuring logs are captured both in the terminal and on disk.

---

## Complexity Hotspots (Warnings)

- **`ai/agent-launcher.sh`**: Uses a procedural registry (large `case` statements) for agent and workflow selection. When adding new agents, you must update multiple functions (`supports_workflow_suffix`, `resolve_workflow_prompt`, `execute_agent`, etc.).
- **`ai/agent-inventory.sh`**: Relies on manual JSON/TOML parsing and directory traversal to build the AI tool inventory. Ensure changes to config locations are reflected here.

---

## Adding a Script

1. Create `scripts/<category>/<name>.sh`.
2. Start with the mandatory `#!/usr/bin/env bash` and `set -euo pipefail`.
3. Source `../lib/logging.sh` for standard logging.
4. Add a unit test file `<name>-test.sh`.
5. If the script is referenced from Nix, use `pkgs.writeShellApplication` in the relevant Nix module to manage runtime dependencies.
6. Run `just lint` to verify with `shellcheck`.

## Nix Integration Table

| Script                                             | Referenced By                                                                    |
| -------------------------------------------------- | -------------------------------------------------------------------------------- |
| `build/modules-check.sh`                           | `justfile` (`just modules`)                                                      |
| `build/packages-check.sh`                          | `justfile` (`just pkgs`)                                                         |
| `build/shellcheck-nix-inline.sh`                   | `justfile` (`just lint`)                                                         |
| `system/report/system-report.sh`                   | `nixos-modules/system-report.nix` (wrapped with `writeShellApplication`)         |
| `system/report/report-collectors.sh`               | Sourced by `system-report.sh` (loads module files)                               |
| `system/report/report-collectors-core.sh`          | Sourced by `system/report/report-collectors.sh`                                  |
| `system/report/report-collectors-observability.sh` | Sourced by `system/report/report-collectors.sh`                                  |
| `system/report/report-collectors-security.sh`      | Sourced by `system/report/report-collectors.sh`                                  |
| `system/report/report-helpers.sh`                  | Sourced by `system-report.sh`                                                    |
| `ai/api-quota/api-quota.sh`                        | `home-manager/modules/noctalia/default.nix` (bar widget)                         |
| `ai/agent-launcher.sh`                             | `home-manager/modules/ai-agents/services.nix` (`ai-agent-launcher` wrapper)      |
| `ai/agent-log-wrapper.sh`                          | `home-manager/modules/ai-agents/services.nix` (`ai-agent-log-wrapper` wrapper)   |
| `ai/agent-analyze.sh`                              | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-analyze` wrapper)   |
| `ai/agent-patterns.sh`                             | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-patterns` wrapper)  |
| `ai/agent-dashboard.sh`                            | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-dashboard` wrapper) |
| `ai/agent-inventory.sh`                            | `home-manager/modules/ai-agents/services.nix` (`ai-agent-inventory` wrapper)     |
| `ai/android-re/re-avd.sh`                          | `home-manager/modules/ai-agents/services.nix` (RE launcher wrapper)              |
| `ai/android-re/re-static.sh`                       | Manual Android RE static-analysis workflow usage                                 |
| `ai/skills-sync.sh`                                | `justfile` (`just skills-sync`)                                                  |
| `sops/sops-edit.sh`                                | `justfile` (`just sops-edit`)                                                    |
| `apps/browser-select.sh`                           | `home-manager/modules/apps/desktop-entries.nix` (`browser-select` wrapper)       |
| `apps/element-desktop-keyring.sh`                  | `home-manager/modules/apps/_desktop-local-bin-wrappers.nix` (local bin wrapper)  |
| `apps/playwright-cli-mcp-wrapper.sh`               | `home-manager/modules/programming-languages/javascript/default.nix` (MCP server) |
| `apps/xdg-open-wrapper.sh`                         | `home-manager/modules/apps/_desktop-local-bin-wrappers.nix` (local bin wrapper)  |
| `apps/youtube-mpv.sh`                              | `home-manager/modules/apps/_desktop-local-bin-wrappers.nix` (local bin wrapper)  |
| `hardware/nvidia-fans.sh`                          | `home-manager/modules/terminal/scripts.nix` (`nvidia-fans` wrapper)              |
