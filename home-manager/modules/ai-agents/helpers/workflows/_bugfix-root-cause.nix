{ mkWorkflow, bugfixOutput, ... }:

mkWorkflow {
  outputContract = bugfixOutput;
  intro = ''
    Resolve a bug or regression by proving the root cause before applying a fix.

    Bugfix objective:
    - Reproduce the issue reliably, identify the exact failing path, and fix the smallest root cause that explains the observed behavior.
    - Prefer a single clear causal chain over multiple speculative fixes.
    - Treat regressions, flaky behavior, configuration drift, data-shape mismatches, and environment-specific failures as bugs that still need evidence-backed diagnosis.
  '';
  body = ''
    Debugging sequence:
    1) Capture the exact symptom, error text, failing command, or user-visible behavior.
    2) Reproduce it with the narrowest reliable path available.
    3) Compare broken versus expected or previously working behavior using code, config, logs, diffs, or recent changes.
    4) Trace the failure backward until you can state one concrete root-cause hypothesis tied to repository evidence.
    5) Apply the smallest fix that addresses that root cause, not just the symptom.
    6) Re-run the reproduction path and relevant regression checks to prove the issue is resolved.

    Required discipline:
    - If you cannot reproduce the issue directly, gather stronger evidence before editing and label the uncertainty explicitly.
    - Prefer a stable reproduction path that can be rerun before and after the fix; if the original report is flaky, tighten it into the closest reliable repro instead of hand-waving the symptom.
    - If a test or checker can be added or updated to guard against recurrence, include that as part of the fix when appropriate to the repository.
    - If the first hypothesis fails, stop and form a new one from new evidence rather than stacking guesses.

    Cross-project adaptation:
    - In apps/services: verify runtime path, request/response flow, state transitions, and user-visible regressions.
    - In libraries/SDKs: verify API contract, versioned behavior, compatibility surface, and edge-case handling.
    - In CLI/scripts/config repos: verify command semantics, environment assumptions, path handling, and shell/config evaluation behavior.
    - In infra/IaC: verify plan/eval/apply path, environment-specific drift, and safety of the remediation path.
  '';
  domainRules = ''
    Bugfix hard rules:
    - Do not patch around the symptom while leaving the identified root cause in place.
    - Do not call the bug fixed if the original or closest trustworthy reproduction path was not rerun after the change.
    - Do not bundle unrelated cleanup into the fix unless it is required for correctness or validation.
    - Do not claim a bug is fixed without rerunning the reproduction path or the closest trustworthy equivalent.
  '';
}
