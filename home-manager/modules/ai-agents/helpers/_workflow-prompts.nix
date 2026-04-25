# Workflow prompt constants used by AI agent shell aliases.
# Each prompt lives in its own file under workflows/; shared sections in workflows/_shared.nix.

_:

let
  shared = import ./workflows/_shared.nix;
in
{
  commitSplit = import ./workflows/_commit-split.nix shared;
  refactorMaintainability = import ./workflows/_refactor-maintainability.nix shared;
  bugfixRootCause = import ./workflows/_bugfix-root-cause.nix shared;
  securityAudit = import ./workflows/_security-audit.nix shared;
  dependencyUpgrade = import ./workflows/_dependency-upgrade.nix shared;
  buildPerformance = import ./workflows/_build-performance.nix shared;
  runtimePerformance = import ./workflows/_runtime-performance.nix shared;
  markdownSync = import ./workflows/_markdown-sync.nix shared;
}
