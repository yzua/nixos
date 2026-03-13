# Utility Scripts

30 executable Bash scripts across `ai/`, `apps/`, `build/`, `hardware/`, `sops/`, `system/`, and `lib/`, plus two shared libraries in `lib/` (`logging.sh`, `test-helpers.sh`). All must pass `shellcheck` (enforced by `just lint`).

---

## Directory Map

```
scripts/
├── ai/
│   ├── ask.sh              # Z.ai API client (GLM-4.5-air/GLM-5, clipboard support)
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
│   └── agent-inventory.sh   # Interactive fzf inventory for AI tools (skills, MCP, agents)
├── apps/
│   └── browser-select.sh    # Browser profile selector (wofi menu)
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

- Shebang: `#!/usr/bin/env bash` + `set -euo pipefail`
- **Sourced libraries** (`lib/`): Do NOT include `set -euo pipefail` (inherited from caller)
- Quote all variables: `"$var"`, `"${array[@]}"`
- Conditionals: `[[ ... ]]` (not `[ ... ]`)
- Arrays: `mapfile` for reading from commands
- Error handling: `error_exit "message" code`
- Logging: Source `scripts/lib/logging.sh` — never define `log_info`/`print_info` locally
- Test files: `*-test.sh` suffix, same directory as source

---

## Shared Logging Library (`lib/logging.sh`)

Functions: `print_info`, `print_success`, `print_warning`, `print_error` (colored), `log_info`, `log_warning`, `log_error`, `log_success` (timestamped, optional file logging).

```bash
source "$(dirname "$0")/../lib/logging.sh"
```

---

## Adding a Script

1. Create `scripts/<category>/<name>.sh`
2. Start with `#!/usr/bin/env bash` and `set -euo pipefail`
3. Source `../lib/logging.sh` for logging (adjust relative path)
4. Add test file `<name>-test.sh` if testable
5. If referenced from Nix modules, use `pkgs.writeShellApplication` with runtime deps
6. Run: `just lint` (includes shellcheck)

## Scripts Referenced from Nix

| Script                                             | Referenced By                                                                         |
| -------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `build/modules-check.sh`                           | `justfile` (`just modules`)                                                           |
| `build/packages-check.sh`                          | `justfile` (`just pkgs`)                                                              |
| `build/shellcheck-nix-inline.sh`                   | `justfile` (`just lint`)                                                              |
| `system/report/system-report.sh`                   | `nixos/modules/system-report.nix` (wrapped with `writeShellApplication`)              |
| `system/report/report-collectors.sh`               | Sourced by `system-report.sh` (loads module files)                                    |
| `system/report/report-collectors-core.sh`          | Sourced by `system/report/report-collectors.sh`                                       |
| `system/report/report-collectors-observability.sh` | Sourced by `system/report/report-collectors.sh`                                       |
| `system/report/report-collectors-security.sh`      | Sourced by `system/report/report-collectors.sh`                                       |
| `system/report/report-helpers.sh`                  | Sourced by `system-report.sh`                                                         |
| `ai/api-quota/api-quota.sh`                        | `home-manager/modules/noctalia/default.nix` (bar widget)                              |
| `ai/agent-launcher.sh`                             | `home-manager/modules/ai-agents/services.nix` (`ai-agent-launcher` wrapper)           |
| `ai/agent-log-wrapper.sh`                          | `home-manager/modules/ai-agents/_mcp-transforms.nix` (`ai-agent-log-wrapper` wrapper) |
| `ai/agent-analyze.sh`                              | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-analyze` wrapper)        |
| `ai/agent-patterns.sh`                             | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-patterns` wrapper)       |
| `ai/agent-dashboard.sh`                            | `home-manager/modules/ai-agents/log-analyzer.nix` (`ai-agent-dashboard` wrapper)      |
| `ai/agent-inventory.sh`                            | `home-manager/modules/ai-agents/services.nix` (`ai-agent-inventory` wrapper)          |
| `sops/sops-edit.sh`                                | `justfile` (`just sops-edit`)                                                         |
| `apps/browser-select.sh`                           | `home-manager/modules/apps/desktop-entries.nix` (`browser-select` wrapper)            |
| `hardware/nvidia-fans.sh`                          | `home-manager/modules/terminal/scripts.nix` (`nvidia-fans` wrapper)                   |
