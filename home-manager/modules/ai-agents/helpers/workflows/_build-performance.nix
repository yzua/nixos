{ mkWorkflow, performanceOutput, ... }:

mkWorkflow {
  outputContract = performanceOutput;
  intro = ''
    Run a build and delivery performance pass with measurable evidence.

    Scope:
    - Treat performance broadly: build time, eval time, lint/typecheck time, test time, packaging time, Docker image time, task-runner overhead, cache misses, and CI critical-path latency.
    - Optimize the highest-cost feedback loops first, not just the final production build.
  '';
  body = ''
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
  '';
}
