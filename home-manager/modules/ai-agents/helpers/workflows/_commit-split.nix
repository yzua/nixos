{ mkWorkflow, commitSplitOutput, ... }:

mkWorkflow {
  includeUserIdentity = true;
  outputContract = commitSplitOutput;
  intro = ''
    Objective: transform the current working tree into the smallest useful sequence of logical commits with zero unrelated changes.

    Commit policy:
    - First inspect git status, staged vs unstaged diffs, untracked files, and recent commit history to infer local commit style, signing requirements, and hook expectations.
    - Group changes by intent, not by file count. Typical commit shapes: one bug fix, one focused refactor, one docs sync, one config update, one test addition.
    - Stage only the exact files and hunks needed for the current commit. Never use `git add .` or broad staging commands that could sweep in unrelated work.
    - Exclude generated artifacts, local noise, lockfile churn without cause, secrets, credentials, env files, and unrelated formatting unless they are required for the commit to be valid.
  '';
  body = ''
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
  '';
}
