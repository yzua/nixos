{ mkWorkflow, dependencyUpgradeOutput, ... }:

mkWorkflow {
  outputContract = dependencyUpgradeOutput;
  intro = ''
    Upgrade a dependency, package, plugin, tool, runtime, or provider with minimal risk and explicit compatibility handling.

    Upgrade objective:
    - Move from the current version to the target version using the smallest safe migration path.
    - Detect and handle breaking changes, changed defaults, removed APIs, lockfile impacts, and repo-specific compatibility constraints.
    - Preserve repository behavior, developer workflow, build semantics, and deployment assumptions unless the upgrade explicitly requires a documented change.
  '';
  body = ''
    Upgrade sequence:
    1) Identify the dependency or tool, current version, target version, and why the upgrade is being made.
    2) Locate all ownership points: manifests, lockfiles, config files, wrappers, generated pins, CI setup, containers, docs, and runtime references.
    3) Review changelog, release notes, migration guide, deprecation notices, or repository-local evidence of breaking changes when available.
    4) Map the affected surfaces before editing: code imports, config schema, commands, build/test behavior, and runtime assumptions.
    5) Apply the minimal version bump and the smallest necessary migration edits.
    6) Re-run targeted compatibility checks, then broader repo-native validation appropriate to the upgrade surface.

    Cross-project adaptation:
    - For language packages, consider API changes, lockfile churn, generated artifacts, and ecosystem-specific migration guides.
    - For CLIs and developer tools, consider wrapper scripts, flags, output format changes, and docs drift.
    - For containers and infrastructure components, consider image tags, config shape, rollout risk, and environment parity.
    - For monorepos, verify whether the upgrade is local, workspace-wide, or shared via central tooling.

    Required discipline:
    - Treat official migration guidance and release notes as required evidence when they exist; do not rely on version intuition alone.
    - If the target version cannot be adopted safely because of unresolved breaking changes, stop at the proven blocker and report the exact migration gap.
    - Keep the upgrade scoped; do not sneak in unrelated package bumps or broad cleanup unless required by the migration.
    - Update docs, examples, and command references if the upgrade changes user or contributor workflows.
  '';
  domainRules = ''
    Upgrade hard rules:
    - Do not trust version bumps alone; validate the owned runtime surface.
    - Do not assume transitive compatibility when lockfiles, generators, or wrappers are involved.
    - Do not hide breaking changes; either migrate them fully or report them clearly as blockers or follow-ups.
  '';
}
