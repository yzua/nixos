# Codex CLI configuration: model, profiles, custom agents, and developer instructions.

{
  config,
  ...
}:

{
  programs.aiAgents.codex = {
    enable = true;
    useWrapper = true;
    model = "gpt-5.4";
    sandboxMode = "workspace-write";
    enableSearch = false;
    personality = "pragmatic";
    reasoningEffort = "medium";
    approvalPolicy = "on-request";
    features = {
      apps = false;
      child_agents_md = true;
      multi_agent = true;
      plugins = true;
      shell_snapshot = true;
      tool_suggest = true;
      unified_exec = true;
    };
    trustedProjects = [
      "${config.home.homeDirectory}/System"
    ];
    profiles = {
      quick = {
        reasoningEffort = "low";
      };
      deep = {
        reasoningEffort = "xhigh";
        approvalPolicy = "on-request";
        sandboxMode = "workspace-write";
      };
      safe = {
        approvalPolicy = "untrusted";
        sandboxMode = "read-only";
      };
      review = {
        personality = "pragmatic";
        reasoningEffort = "high";
        approvalPolicy = "on-request";
        developerInstructions = ''
          Run in review mode. Prioritize bugs, regressions, security issues, and missing tests.
          Findings come first with exact file and line references when available.
        '';
      };
    };
    customAgents = {
      reviewer = {
        description = "Review-focused agent for bugs, regressions, security issues, and missing tests.";
        reasoningEffort = "high";
        approvalPolicy = "on-request";
        sandboxMode = "read-only";
        developerInstructions = ''
          Perform code review only. Do not implement changes.
          Prioritize correctness, behavior drift, security issues, and test gaps.
          Findings must be concise, ordered by severity, and include exact evidence.
        '';
      };
      recon = {
        description = "Read-heavy reverse-engineering triage agent for static inspection and evidence gathering.";
        reasoningEffort = "high";
        approvalPolicy = "on-request";
        sandboxMode = "read-only";
        enableSearch = true;
        developerInstructions = ''
          Focus on static triage and evidence gathering.
          Map strings, imports, symbols, embedded endpoints, protocols, config formats, and trust boundaries.
          Do not mutate files or run samples unless explicitly asked.
        '';
      };
    };
    extraToml = ''
      [agents]
      max_threads = 4

      [agents.explorer]
      description = "Read-only style codebase exploration, file tracing, and evidence gathering."

      [agents.worker]
      description = "Targeted implementation and fixes after the task is understood."

      [agents.monitor]
      description = "Long-running command, build, and polling monitor with concise status updates."
    '';
  };
}
