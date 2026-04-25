{ mkWorkflow, markdownOutput, ... }:

mkWorkflow {
  useChangeControl = false;
  outputContract = markdownOutput;
  intro = ''
    Synchronize markdown and operator-facing docs with current repository reality.

    Scope:
    - README files, AGENTS guides, docs/ trees, guides, onboarding docs, CONTRIBUTING/DEVELOPMENT notes, runbooks, templates, and any markdown that instructs humans or agents how the repo works.
    - Treat code, config, scripts, and generated runtime behavior as the source of truth when documentation drifts.
  '';
  body = ''
    Method:
    - Verify every command, path, option, workflow, architecture claim, dependency statement, environment requirement, and validation instruction against current repository files and actual command surfaces.
    - Fix contradictions, stale references, missing prerequisites, misleading examples, and vague instructions.
    - Preserve local terminology and guidance tone unless clarity or accuracy requires a rewrite.
    - Prefer deterministic commands, concrete paths, and scoped examples over narrative hand-waving.

    Special handling:
    - Remove or rewrite aspirational claims that are not implemented.
    - If documentation spans multiple repo types or optional stacks, clearly mark which instructions apply to which case.
    - If a statement cannot be verified locally, either remove it or label it as needing human confirmation.
  '';
}
