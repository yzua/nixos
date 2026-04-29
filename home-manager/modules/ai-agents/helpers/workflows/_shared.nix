# Shared sections and output contracts for workflow prompts.

let
  joinSections = sections: builtins.concatStringsSep "\n\n" sections;

  userIdentity = ''
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

  searchDiscipline = ''
    Search discipline:
    - Start with targeted discovery: the few files, symbols, commands, configs, or docs most likely to control the requested behavior.
    - Prefer high-signal local evidence first: neighboring files, import hubs, entrypoints, tests, wrappers, and recent usage sites.
    - Read only as much as needed to act safely; do not wander through unrelated files once the relevant path is established.
    - If the first search path is weak, tighten the query and try again instead of broad random exploration.
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

  blockerHandling = ''
    Blocker handling:
    - If evidence is missing or conflicting, say exactly what is unknown and what file, command, or runtime signal would resolve it.
    - If validation fails, report the exact failing command, the failing surface, and whether the failure appears caused by your change or was already present.
    - If multiple viable paths exist, choose the lowest-risk reversible path that matches repository conventions and explain the tradeoff briefly.
    - If you cannot complete part of the workflow safely, stop at the proven blocker instead of guessing past it.
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

  scopeDiscipline = ''
    Scope discipline:
    - Freeze scope around the requested outcome once the relevant path is identified.
    - Expand scope only when required for correctness, safety, compatibility, or validation.
    - Record adjacent cleanup, redesign, or hardening ideas as deferred follow-ups instead of folding them into the active change.
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
    - End with what is verified, what remains inferred, residual risk, unverified edges, and any follow-up hardening that was intentionally deferred.
  '';

  securityAuditOutput = ''
    Output contract:
    - For every finding include severity, affected surface, exploitability, impact, exact path and line when possible, repository evidence, the minimal stack-native remediation, and the concrete verification step.
    - Include exploit preconditions and trust-boundary crossed so severity reflects the real attack path instead of the sink alone.
    - Separate confirmed findings from weaker concerns or evidence gaps; do not present them at the same confidence level.
    - End with a prioritized remediation backlog split into immediate fixes, short-term hardening, and structural follow-ups.
  '';

  dependencyUpgradeOutput = ''
    Output contract:
    - State the dependency or tool upgraded, old and new versions, upgrade motivation, affected surfaces, migration edits, and validation evidence.
    - Call out breaking changes handled, remaining compatibility risks, and any deferred cleanup or follow-up migrations.
    - If the upgrade was blocked, report the blocker with the exact file, command, release note, migration gap, or compatibility issue that stopped progress.
  '';

  performanceOutput = ''
    Output contract:
    - Include the baseline command or measurement set, measured timings or resource metrics, bottlenecks identified, optimization steps applied, post-change measurements, and the absolute plus percentage deltas.
    - If no trustworthy measurement path exists, state that limitation clearly and switch to evidence-backed static analysis instead of fake numbers.
  '';

  markdownOutput = ''
    Output contract:
    - List every file updated, every claim re-verified, every command or path revalidated, and any remaining documentation gaps that need human decisions.
    - Prefer concise factual corrections over stylistic rewriting.
  '';

  sharedSections = [
    repoDiscovery
    searchDiscipline
    validationDiscovery
    evidenceDiscipline
    scopeDiscipline
    blockerHandling
  ];

  sharedSectionsWithChangeControl = sharedSections ++ [ changeControl ];
  mkWorkflow =
    {
      intro,
      body,
      outputContract,
      useChangeControl ? true,
      includeUserIdentity ? false,
      domainRules ? "",
    }:
    let
      prefix = [ intro ] ++ (if includeUserIdentity then [ userIdentity ] else [ ]);
      sections = if useChangeControl then sharedSectionsWithChangeControl else sharedSections;
      suffix = [
        body
        universalHardRules
      ]
      ++ (if domainRules != "" then [ domainRules ] else [ ])
      ++ [ outputContract ];
    in
    joinSections (prefix ++ sections ++ suffix);

in
{
  inherit mkWorkflow;
  inherit
    commitSplitOutput
    refactorOutput
    bugfixOutput
    securityAuditOutput
    dependencyUpgradeOutput
    performanceOutput
    markdownOutput
    ;
}
