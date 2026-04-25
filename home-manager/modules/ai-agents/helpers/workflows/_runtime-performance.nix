{ mkWorkflow, performanceOutput, ... }:

mkWorkflow {
  outputContract = performanceOutput;
  intro = ''
    Run a code-performance pass with measurable evidence.

    Scope:
    - Optimize real execution paths: request latency, throughput, CPU time, memory or allocations, query count, render and interaction jank, startup time, background job cost, I/O volume, cache effectiveness, and needless repeated work.
    - Treat build, lint, and CI speed as out of scope unless they directly block the measured code path; use the build-performance workflow for delivery pipeline bottlenecks.
  '';
  body = ''
    Sequence:
    1) Detect the performance-critical code path and the repository's real measurement tools: benchmarks, profilers, traces, tests, load tools, browser or devtools traces, flamegraphs, query logs, or stable local repro commands.
    2) Capture a trustworthy baseline for the target path before editing.
    3) Identify the highest-impact bottleneck from measurements, traces, query counts, allocations, render cost, or code-level evidence.
    4) Apply the smallest low-risk optimization that meaningfully reduces that bottleneck.
    5) Re-run the exact same measurement path and compare the result.
    6) Re-run correctness validation so the optimization does not silently change behavior.

    Cross-project adaptation:
    - For web, mobile, and desktop apps, focus on startup, interaction latency, render cost, network chatter, cache behavior, and heavy client-side work.
    - For services and APIs, focus on hot endpoints, database access, serialization, concurrency limits, background jobs, and I/O overhead.
    - For libraries, SDKs, CLIs, and scripts, focus on algorithmic complexity, unnecessary copies, streaming vs buffering, startup overhead, and memory churn.
    - For infra, config, and data repos, focus on repeated evaluation, unnecessary breadth, heavy generation steps, and operational hot paths rather than cosmetic micro-optimizations.
  '';
  domainRules = ''
    Performance hard rules:
    - Do not replace a measured bottleneck with speculative micro-optimizations.
    - Do not trade away correctness, safety, or maintainability unless the tradeoff is explicit and justified by the measured gain.
    - Do not claim a performance improvement without before-and-after evidence or clearly labeled static reasoning when measurement is impossible.
  '';
}
