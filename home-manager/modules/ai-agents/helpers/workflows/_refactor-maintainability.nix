{ mkWorkflow, refactorOutput, ... }:

mkWorkflow {
  outputContract = refactorOutput;
  intro = ''
    Goal: improve maintainability and clarity with zero unintended behavior drift.

    Maintainability focus:
    - Target only issues with concrete payoff: real duplication, mixed responsibilities, oversized units, weak module boundaries, inconsistent abstractions, dead or misleading paths, or hard-to-validate code layout.
    - Favor simpler structure, clearer ownership, better naming, and better validation locality over abstract cleverness.
    - If a refactor target is too large or mixed-purpose, you may split it into smaller focused files or directories when that clearly improves readability and maintainability.
    - For the specific language, framework, tool, or config system being refactored, search for and apply relevant stack-specific best practices instead of relying only on generic refactor advice.
    - Preserve public behavior, commands, schemas, API contracts, and user-visible semantics unless a migration is explicitly part of the task.
  '';
  body = ''
    Sequence:
    1) Capture the current architecture and module boundaries from the existing tree.
    2) Run baseline diagnostics and identify the smallest high-payoff refactor target.
    3) Produce a ranked file-level plan before editing, including expected payoff and risk.
    4) Implement in atomic steps that keep the code working after each step.
    5) Re-run relevant validation after each meaningful refactor boundary.
    6) Stop once the highest-value maintainability gains are achieved; do not continue into style churn.

    Cross-project adaptation:
    - In apps/services: improve feature boundaries, dependency flow, and readability of critical paths.
    - In libraries/SDKs: improve API clarity, internal layering, and testability without accidental breaking changes.
    - In infra/config repos: reduce copy-paste, make intent obvious, and improve safety of shared configuration patterns.
    - In docs-heavy repos: focus on information architecture, repeated guidance, stale duplication, and clearer source-of-truth boundaries.
  '';
}
