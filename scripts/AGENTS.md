# Utility Scripts

15 Bash scripts across 5 categories + 1 shared library. All must pass `shellcheck` (enforced by `just lint`).

---

## Directory Map

```
scripts/
├── ai/
│   ├── ask.sh              # Z.ai API client (GLM-4.5-air/GLM-5, clipboard support)
│   ├── api-quota.sh         # Noctalia bar widget: Z.ai + Claude Max + Codex usage JSON
│   └── api-quota-test.sh    # Unit tests for api-quota.sh
├── build/
│   ├── modules-check.sh     # Validates default.nix imports match .nix files on disk
│   ├── modules-check-test.sh # Unit tests for modules-check.sh
│   ├── pre-commit-hook.sh   # Git hook: modules → lint → format → check
│   ├── pre-push-hook.sh     # Git hook: enforces GPG-signed commits
│   └── shellcheck-nix-inline.sh # Lints inline Bash in writeShellScript blocks
├── lib/
│   └── logging.sh           # Shared logging library (colored output, timestamps)
├── sops/
│   └── sops-edit.sh         # Secrets editor (RAM-backed tmpfs, age encryption)
├── system/
│   ├── system-report.sh     # Unified health report (full/errors mode)
│   ├── report-collectors.sh # Collectors: systemd, Loki, Netdata, Scrutiny, security
│   ├── report-helpers.sh    # Report generation helper functions
│   └── report-collectors-test.sh # Unit tests for report collectors
└── nvidia-fans.sh           # GPU fan control
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

| Script | Referenced By |
|--------|-------------|
| `build/modules-check.sh` | `justfile` (`just modules`) |
| `build/shellcheck-nix-inline.sh` | `justfile` (`just lint`) |
| `system/system-report.sh` | `nixos/modules/system-report.nix` (wrapped with `writeShellApplication`) |
| `system/report-collectors.sh` | Sourced by `system-report.sh` |
| `system/report-helpers.sh` | Sourced by `system-report.sh` |
| `ai/api-quota.sh` | `home-manager/modules/noctalia/default.nix` (bar widget) |
| `sops/sops-edit.sh` | `justfile` (`just sops-edit`) |
