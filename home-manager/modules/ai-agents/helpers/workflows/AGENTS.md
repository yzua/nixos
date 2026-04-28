# Workflow Prompts

Structured workflow prompt definitions for AI agent slash commands. Each file is a pure Nix expression that produces a prompt string via the shared `mkWorkflow` constructor.

---

## Files

| File                         | Workflow             | Output Contract                                              |
| ---------------------------- | -------------------- | ------------------------------------------------------------ |
| `_shared.nix`                | (Infrastructure)     | `mkWorkflow` constructor, shared sections, output contracts  |
| `_bugfix-root-cause.nix`     | Bugfix               | Symptom → root cause → minimal fix → regression validation  |
| `_build-performance.nix`     | Build performance    | Baseline timings → bottleneck → optimization → delta         |
| `_commit-split.nix`          | Commit splitting     | Inspect diff → commit plan → staged hunks → validate per commit |
| `_dependency-upgrade.nix`    | Dependency upgrade   | Version diff → migration edits → compatibility validation    |
| `_markdown-sync.nix`         | Markdown sync        | File list → claim verification → command revalidation        |
| `_refactor-maintainability.nix` | Refactoring       | Ranked issues → chosen edits → per-step validation → debt map |
| `_runtime-performance.nix`   | Runtime performance  | Measurement set → bottleneck → fix → before/after metrics    |
| `_security-audit.nix`        | Security audit       | Threat model → findings by evidence → prioritized backlog    |

---

## Architecture

All workflows use `mkWorkflow` from `_shared.nix`:

```nix
mkWorkflow {
  intro = "...";              # Objective and scope
  body = "...";               # Execution sequence
  outputContract = ...;       # From shared output contract library
  useChangeControl = true;    # Include change control sections (default: true)
  includeUserIdentity = false; # Include git identity section
  domainRules = "...";        # Extra domain-specific hard rules (optional)
}
```

### Shared sections

Every workflow includes these sections automatically (from `_shared.nix`):
- Repo discovery, search discipline, validation discovery, evidence discipline, scope discipline, blocker handling
- When `useChangeControl = true`: change control section is added

---

## Adding a Workflow

1. Create `_new-workflow.nix` following the `mkWorkflow` pattern.
2. If the output contract is new, add it to `_shared.nix`.
3. Register in `../_workflow-prompts.nix` (the aggregation point that maps workflow names to prompt strings).
4. Wire into agent slash commands via the appropriate model config (e.g., `config/models/opencode.nix` for OpenCode commands).

---

## Gotchas

- `_security-audit.nix` sets `useChangeControl = false` because audits are read-only.
- `_commit-split.nix` sets `includeUserIdentity = true` because it creates git commits.
- Workflows are plain strings, not modules — imported directly by `_workflow-prompts.nix`.
- The `universalHardRules` section is appended automatically to every workflow.
