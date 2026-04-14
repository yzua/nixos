# Workflow prompt constants used by AI agent shell aliases.
# Optionally accepts `constants` from shared/constants.nix for user identity.
# Falls back to git config lookup if not provided.

{
  constants ? null,
}:

let
  # Extract user info from constants if available, otherwise use defaults
  userInfo =
    if constants != null && constants ? user then
      (builtins.removeAttrs constants.user [ "githubEmail" ])
    else
      null;
  joinSections = sections: builtins.concatStringsSep "\n\n" sections;

  # Git user identity - extracted from constants when available
  userIdentity =
    if userInfo != null then
      ''
        Git user identity (use for commits):
        - Name: ${userInfo.handle}
        - Email: ${userInfo.email}
        - GPG signing key: ${userInfo.signingKey}
        - Use GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL/GIT_COMMITTER_NAME/GIT_COMMITTER_EMAIL or `git commit --author` for correct attribution.
        - If commits fail GPG signing due to timeout, use `-c commit.gpgsign=false` as fallback but note the issue.
      ''
    else
      ''
        Git user identity:
        - Use those values with GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL or `git commit --author` for correct attribution.
      '';

  repoDiscovery = ''
    Repository discovery:
    - Classify the repository before doing domain work: application, library, CLI tool, service, docs-only repo, infrastructure/IaC, polyglot monorepo, or personal dotfiles/config.
    - Detect the actual stack and workflow from source-of-truth files instead of guessing: justfile, Makefile, flake.nix, package.json, pnpm-workspace.yaml, pyproject.toml, requirements files, Cargo.toml, go.mod, Dockerfile, compose files, terraform files, CI workflows, and top-level docs.
    - Identify entrypoints, package boundaries, public interfaces, deployment surfaces, and any existing architectural conventions from the current tree.
    - Prefer local conventions over generic best practices when both are viable.
  '';

  validationDiscovery = ''
    Validation discovery:
    - Determine the narrowest relevant validation commands from the repository itself before editing or claiming completion.
    - Prefer repository-native entrypoints first: just/make targets, package manager scripts, language-native checks, CI-aligned commands, repo wrappers, and documented verification flows.
    - If multiple checks exist, run the smallest targeted checks first, then broader checks appropriate to the scope.
    - If the repo has no meaningful automated validation for the touched surface, say that explicitly instead of inventing one.
  '';

  evidenceDiscipline = ''
    Evidence discipline:
    - Verify claims with file evidence, command output, exact paths, and concrete observations.
    - Separate verified facts from inference.
    - Do not claim success based on intent, plausibility, or style; claim success only after matching validation evidence.
  '';

  universalHardRules = ''
    Universal hard rules:
    - Do not invent scripts, commands, files, framework conventions, APIs, or deployment workflows that are not present in the repository.
    - Do not perform speculative rewrites or broad refactors unrelated to the stated workflow.
    - Do not hide uncertainty; surface missing information, missing validation, and residual risk explicitly.
    - Keep changes consistent with local naming, file layout, error handling, and tooling patterns.
  '';

  changeControl = ''
    Change control:
    - Start with the highest-signal files and the smallest change set that can improve the target outcome.
    - Preserve public behavior, documented contracts, user-facing semantics, and repo workflows unless the task explicitly requires changing them.
    - Prefer reversible, low-blast-radius edits over sweeping transformations.
  '';

  commitSplitOutput = ''
    Output contract:
    - Show the proposed commit plan before the first commit.
    - For each commit, report the scope, commit message, validation run, and resulting commit hash.
    - End with the remaining git status and any intentionally uncommitted work.
  '';

  refactorOutput = ''
    Output contract:
    - Report the ranked maintainability issues found, the chosen edits, the validation run after each meaningful step, and any residual architectural debt left untouched on purpose.
    - Map each applied change to a specific maintainability gain such as clearer ownership, reduced duplication, smaller surface area, or cleaner boundaries.
  '';

  bugfixOutput = ''
    Output contract:
    - State the reproduced symptom, exact root cause, affected path, fix applied, and the regression validation that proves the issue is resolved.
    - Distinguish verified root cause from remaining hypotheses or adjacent concerns.
    - End with residual risk, unverified edges, and any follow-up hardening that was intentionally deferred.
  '';

  securityAuditOutput = ''
    Output contract:
    - For every finding include severity, affected surface, exploitability, impact, exact path and line when possible, repository evidence, the minimal stack-native remediation, and the concrete verification step.
    - End with a prioritized remediation backlog split into immediate fixes, short-term hardening, and structural follow-ups.
  '';

  dependencyUpgradeOutput = ''
    Output contract:
    - State the dependency or tool upgraded, old and new versions, upgrade motivation, affected surfaces, migration edits, and validation evidence.
    - Call out breaking changes handled, remaining compatibility risks, and any deferred cleanup or follow-up migrations.
    - If the upgrade was blocked, report the blocker with the exact file, command, or compatibility issue that stopped progress.
  '';

  performanceOutput = ''
    Output contract:
    - Include the baseline command set, measured timings, bottlenecks identified, optimization steps applied, post-change timings, and the absolute plus percentage deltas.
    - If no trustworthy measurement path exists, state that limitation clearly and switch to evidence-backed static analysis instead of fake numbers.
  '';

  markdownOutput = ''
    Output contract:
    - List every file updated, every claim re-verified, every command or path revalidated, and any remaining documentation gaps that need human decisions.
    - Prefer concise factual corrections over stylistic rewriting.
  '';
in
{
  commitSplit = joinSections [
    ''
      Objective: transform the current working tree into the smallest useful sequence of logical commits with zero unrelated changes.

      Commit policy:
      - First inspect git status, staged vs unstaged diffs, untracked files, and recent commit history to infer local commit style, signing requirements, and hook expectations.
      - Group changes by intent, not by file count. Typical commit shapes: one bug fix, one focused refactor, one docs sync, one config update, one test addition.
      - Stage only the exact files and hunks needed for the current commit. Never use `git add .` or broad staging commands that could sweep in unrelated work.
      - Exclude generated artifacts, local noise, lockfile churn without cause, secrets, credentials, env files, and unrelated formatting unless they are required for the commit to be valid.
    ''
    userIdentity
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    changeControl
    ''
      Execution sequence:
      1) Build an ordered commit plan with rationale and expected validation for each commit.
      2) Create the first commit by staging only relevant hunks and files.
      3) Run the narrowest validation needed for the touched surface, then broader repo-native checks only if justified by the scope.
      4) Commit using the repository's established message style and signing policy.
      5) Re-check git status and repeat until the full plan is complete or you encounter a blocker.

      Special cases:
      - Docs-only or comment-only changes still require checking whether examples, commands, or adjacent generated docs need refresh.
      - Config-only changes should verify the repo's configuration evaluation, lint, or dry-run path where available.
      - If the working tree contains overlapping concerns that cannot be safely split, call that out before committing rather than forcing an unsafe split.
    ''
    universalHardRules
    commitSplitOutput
  ];

  refactorMaintainability = joinSections [
    ''
      Goal: improve maintainability and clarity with zero unintended behavior drift.

      Maintainability focus:
      - Target only issues with concrete payoff: real duplication, mixed responsibilities, oversized units, weak module boundaries, inconsistent abstractions, dead or misleading paths, or hard-to-validate code layout.
      - Favor simpler structure, clearer ownership, better naming, and better validation locality over abstract cleverness.
      - Preserve public behavior, commands, schemas, API contracts, and user-visible semantics unless a migration is explicitly part of the task.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    changeControl
    ''
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
    ''
    universalHardRules
    refactorOutput
  ];

  bugfixRootCause = joinSections [
    ''
      Resolve a bug or regression by proving the root cause before applying a fix.

      Bugfix objective:
      - Reproduce the issue reliably, identify the exact failing path, and fix the smallest root cause that explains the observed behavior.
      - Prefer a single clear causal chain over multiple speculative fixes.
      - Treat regressions, flaky behavior, configuration drift, data-shape mismatches, and environment-specific failures as bugs that still need evidence-backed diagnosis.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    changeControl
    ''
      Debugging sequence:
      1) Capture the exact symptom, error text, failing command, or user-visible behavior.
      2) Reproduce it with the narrowest reliable path available.
      3) Compare broken versus expected or previously working behavior using code, config, logs, diffs, or recent changes.
      4) Trace the failure backward until you can state one concrete root-cause hypothesis tied to repository evidence.
      5) Apply the smallest fix that addresses that root cause, not just the symptom.
      6) Re-run the reproduction path and relevant regression checks to prove the issue is resolved.

      Required discipline:
      - If you cannot reproduce the issue directly, gather stronger evidence before editing and label the uncertainty explicitly.
      - If a test or checker can be added or updated to guard against recurrence, include that as part of the fix when appropriate to the repository.
      - If the first hypothesis fails, stop and form a new one from new evidence rather than stacking guesses.

      Cross-project adaptation:
      - In apps/services: verify runtime path, request/response flow, state transitions, and user-visible regressions.
      - In libraries/SDKs: verify API contract, versioned behavior, compatibility surface, and edge-case handling.
      - In CLI/scripts/config repos: verify command semantics, environment assumptions, path handling, and shell/config evaluation behavior.
      - In infra/IaC: verify plan/eval/apply path, environment-specific drift, and safety of the remediation path.
    ''
    universalHardRules
    ''
      Bugfix hard rules:
      - Do not patch around the symptom while leaving the identified root cause in place.
      - Do not bundle unrelated cleanup into the fix unless it is required for correctness or validation.
      - Do not claim a bug is fixed without rerunning the reproduction path or the closest trustworthy equivalent.
    ''
    bugfixOutput
  ];

  securityAudit = joinSections [
    ''
      Run a security audit with evidence only.

      Threat-modeling scope:
      - Inventory trust boundaries, entrypoints, secrets flow, privileged operations, network surfaces, external integrations, storage locations, CI/CD paths, update/install paths, and local execution hooks.
      - Adapt the threat model to the repo type rather than assuming a web app. Consider web, API, CLI, desktop/mobile, scripts, background jobs, containers, infrastructure as code, package publishing, and local automation surfaces as applicable.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    ''
      Audit checklist by evidence:
      - Authentication and authorization correctness.
      - Input handling, injection classes, command execution, unsafe eval, path traversal, SSRF, XSS, CSRF, open redirects, deserialization, and template injection where applicable.
      - Secrets management, credential exposure, token handling, and logging leaks.
      - Cryptography and randomness misuse.
      - File permissions, temp-file safety, unsafe shell usage, privilege escalation paths, and sandbox escape opportunities.
      - Dependency and supply-chain risks, CI workflow trust boundaries, release automation, and update/install integrity.
      - Container, IaC, and deployment posture where the repository owns those concerns.

      Reporting rules:
      - Prefer a smaller set of concrete findings over a generic checklist.
      - Do not duplicate the same root cause across multiple findings unless the exploit surface is materially different.
      - When evidence is insufficient to prove a finding, downgrade it to a clearly labeled concern or gap rather than overstating it.
    ''
    universalHardRules
    securityAuditOutput
  ];

  dependencyUpgrade = joinSections [
    ''
      Upgrade a dependency, package, plugin, tool, runtime, or provider with minimal risk and explicit compatibility handling.

      Upgrade objective:
      - Move from the current version to the target version using the smallest safe migration path.
      - Detect and handle breaking changes, changed defaults, removed APIs, lockfile impacts, and repo-specific compatibility constraints.
      - Preserve repository behavior, developer workflow, build semantics, and deployment assumptions unless the upgrade explicitly requires a documented change.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    changeControl
    ''
      Upgrade sequence:
      1) Identify the dependency or tool, current version, target version, and why the upgrade is being made.
      2) Locate all ownership points: manifests, lockfiles, config files, wrappers, generated pins, CI setup, containers, docs, and runtime references.
      3) Review changelog, release notes, migration guide, or repository-local evidence of breaking changes when available.
      4) Map the affected surfaces before editing: code imports, config schema, commands, build/test behavior, and runtime assumptions.
      5) Apply the minimal version bump and the smallest necessary migration edits.
      6) Re-run targeted compatibility checks, then broader repo-native validation appropriate to the upgrade surface.

      Cross-project adaptation:
      - For language packages, consider API changes, lockfile churn, generated artifacts, and ecosystem-specific migration guides.
      - For CLIs and developer tools, consider wrapper scripts, flags, output format changes, and docs drift.
      - For containers and infrastructure components, consider image tags, config shape, rollout risk, and environment parity.
      - For monorepos, verify whether the upgrade is local, workspace-wide, or shared via central tooling.

      Required discipline:
      - If the target version cannot be adopted safely because of unresolved breaking changes, stop at the proven blocker and report the exact migration gap.
      - Keep the upgrade scoped; do not sneak in unrelated package bumps or broad cleanup unless required by the migration.
      - Update docs, examples, and command references if the upgrade changes user or contributor workflows.
    ''
    universalHardRules
    ''
      Upgrade hard rules:
      - Do not trust version bumps alone; validate the owned runtime surface.
      - Do not assume transitive compatibility when lockfiles, generators, or wrappers are involved.
      - Do not hide breaking changes; either migrate them fully or report them clearly as blockers or follow-ups.
    ''
    dependencyUpgradeOutput
  ];

  buildPerformance = joinSections [
    ''
      Run a build and delivery performance pass with measurable evidence.

      Scope:
      - Treat performance broadly: build time, eval time, lint/typecheck time, test time, packaging time, Docker image time, task-runner overhead, cache misses, and CI critical-path latency.
      - Optimize the highest-cost feedback loops first, not just the final production build.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    changeControl
    ''
      Sequence:
      1) Detect the repository's real build and verification entrypoints.
      2) Capture baseline timings for the commands that matter to this repo.
      3) Identify top bottlenecks from command output, dependency graph shape, cache behavior, repeated work, or obviously expensive configuration.
      4) Apply minimal low-risk optimizations that match the stack and tooling already in use.
      5) Re-run the exact same baseline commands to measure the delta.

      Cross-project adaptation:
      - For Nix/config repos, include evaluation cost and repeated import/config overhead where visible.
      - For JS/TS repos, consider package manager startup, bundler graph cost, lint/typecheck overlap, and test target selection.
      - For Python/Go/Rust repos, consider environment setup, incremental compilation, feature gating, and cache behavior.
      - For monorepos, focus on the slowest path and wasted breadth before touching everything.
    ''
    universalHardRules
    performanceOutput
  ];

  markdownSync = joinSections [
    ''
      Synchronize markdown and operator-facing docs with current repository reality.

      Scope:
      - README files, AGENTS guides, docs/ trees, guides, onboarding docs, CONTRIBUTING/DEVELOPMENT notes, runbooks, templates, and any markdown that instructs humans or agents how the repo works.
      - Treat code, config, scripts, and generated runtime behavior as the source of truth when documentation drifts.
    ''
    repoDiscovery
    validationDiscovery
    evidenceDiscipline
    ''
      Method:
      - Verify every command, path, option, workflow, architecture claim, dependency statement, environment requirement, and validation instruction against current repository files and actual command surfaces.
      - Fix contradictions, stale references, missing prerequisites, misleading examples, and vague instructions.
      - Preserve local terminology and guidance tone unless clarity or accuracy requires a rewrite.
      - Prefer deterministic commands, concrete paths, and scoped examples over narrative hand-waving.

      Special handling:
      - Remove or rewrite aspirational claims that are not implemented.
      - If documentation spans multiple repo types or optional stacks, clearly mark which instructions apply to which case.
      - If a statement cannot be verified locally, either remove it or label it as needing human confirmation.
    ''
    universalHardRules
    markdownOutput
  ];
}
