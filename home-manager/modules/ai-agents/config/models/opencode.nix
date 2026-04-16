# OpenCode model selections, provider registries, agent definitions, and per-agent tool configurations.

{
  config,
  lib,
  ...
}:

let
  models = import ../../helpers/_models.nix;
  workflowPrompts = import ../../helpers/_workflow-prompts.nix { };
  androidReAgent = import ./_opencode-android-re.nix {
    inherit config lib yoloPermission;
  };
  mkAllowPatterns =
    patterns:
    builtins.listToAttrs (
      map (pattern: {
        name = pattern;
        value = "allow";
      }) patterns
    );
  readOnlyBashPatterns = mkAllowPatterns [
    "pwd"
    "pwd *"
    "ls"
    "ls *"
    "find *"
    "rg"
    "rg *"
    "grep *"
    "sed *"
    "cat *"
    "head *"
    "tail *"
    "wc *"
    "stat *"
    "tree *"
    "file *"
    "strings *"
    "jq *"
    "git status*"
    "git diff*"
    "git log*"
    "git show*"
    "git branch*"
    "git ls-files*"
  ];
  yoloPermission = "allow";
  readOnlyPermission = {
    read = "allow";
    edit = "deny";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = readOnlyBashPatterns;
    task = "allow";
    todowrite = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    codesearch = "allow";
    lsp = "allow";
    external_directory = "deny";
    doom_loop = "deny";
    skill = "allow";
  };
in
{
  programs.aiAgents.opencode = {
    enable = true;
    model = models.claude-opus;
    defaultAgent = "build";
    permission = yoloPermission;

    plugins = [
      "opencode-gemini-auth@latest"
    ];

    command = {
      "commit-split" = {
        description = "Split current changes into minimal logical signed commits";
        agent = "patch";
        subtask = true;
        template = workflowPrompts.commitSplit;
      };
      refactor = {
        description = "Raise maintainability without behavior drift";
        agent = "patch";
        subtask = true;
        template = workflowPrompts.refactorMaintainability;
      };
      "security-audit" = {
        description = "Run an evidence-first security review";
        agent = "review";
        subtask = true;
        template = workflowPrompts.securityAudit;
      };
      "build-perf" = {
        description = "Measure and improve build bottlenecks";
        agent = "build";
        subtask = true;
        template = workflowPrompts.buildPerformance;
      };
      "runtime-perf" = {
        description = "Measure and improve runtime/code bottlenecks";
        agent = "optimize";
        subtask = true;
        template = workflowPrompts.runtimePerformance;
      };
      "markdown-sync" = {
        description = "Sync docs with current repository behavior";
        agent = "patch";
        subtask = true;
        template = workflowPrompts.markdownSync;
      };
    };

    agent = {
      plan = {
        model = models.claude-sonnet;
        description = "Primary planning agent for specs, decomposition, and research-backed execution plans.";
        mode = "primary";
        steps = 8;
        permission = readOnlyPermission;
        prompt = ''
          Produce implementation plans that are decision-complete before execution starts.
          Clarify goal, constraints, validation path, interfaces, and rollout risks.
          Prefer evidence from repository files, generated config, and current tool output over assumptions.
        '';
      };
      build = {
        model = models.claude-opus;
        description = "Primary implementation agent for coding work with repo-native validation.";
        mode = "primary";
        steps = 20;
        permission = yoloPermission;
        prompt = ''
          Implement minimal, high-leverage changes that match repository conventions.
          Reuse local patterns, validate with narrow checks first, and avoid speculative refactors.
          Treat formatter, lint, eval, and build output as required evidence before claiming success.
        '';
      };
      review = {
        model = models.claude-sonnet;
        description = "Subagent for bugs, regressions, security issues, and test gaps.";
        mode = "subagent";
        color = "warning";
        steps = 12;
        permission = readOnlyPermission;
        prompt = ''
          Review code and configuration changes for correctness first.
          Prioritize concrete bugs, behavioral regressions, security issues, and missing validation.
          Do not edit files. Report exact evidence with file and line references when available.
        '';
      };
      recon = {
        model = models.gpt-default;
        description = "Subagent for reverse-engineering triage, static inspection, and evidence gathering.";
        mode = "subagent";
        color = "info";
        steps = 16;
        permission = yoloPermission;
        prompt = ''
          Focus on reverse-engineering and static triage.
          Map binaries, strings, symbols, endpoints, protocols, config formats, persistence, and trust boundaries.
          Prefer non-mutating inspection and summarize likely next probes before suggesting dynamic work.
        '';
      };
      patch = {
        model = models.claude-sonnet;
        description = "Subagent for bounded edits, validation passes, and commit shaping.";
        mode = "subagent";
        color = "accent";
        steps = 10;
        permission = yoloPermission;
        prompt = ''
          Make tightly scoped edits against an existing plan or clearly bounded task.
          Preserve behavior unless the task explicitly changes behavior.
          After edits, run the narrowest relevant validation and summarize residual risk.
        '';
      };
      optimize = {
        model = models.claude-opus;
        description = "Subagent for performance profiling, bottleneck analysis, and low-risk speedups across codebases.";
        mode = "subagent";
        color = "accent";
        steps = 14;
        permission = yoloPermission;
        prompt = ''
          Optimize runtime performance with evidence, not guesses.
          Measure the real hot path first, prefer the highest-impact low-risk change, and preserve correctness plus repository conventions.
          Report before-and-after performance evidence, correctness validation, and any tradeoffs left in place.
        '';
      };
    }
    // androidReAgent;

    lsp = import ./_opencode-lsp.nix;

    experimental = {
      batch_tool = true;
      continue_loop_on_deny = true;
      mcp_timeout = 120000;
      openTelemetry = config.programs.aiAgents.logging.enableOtel;
    };

    extraSettings = {
      share = "disabled";
      autoupdate = true;
      small_model = models.claude-haiku; # Cheap model for titles, summaries
      compaction = {
        auto = true;
        prune = true; # Remove old tool outputs during compaction
        reserved = 10000; # Reserved tokens after compaction
      };
    };

    providers = {
      openrouter = {
        options = {
          apiKey = "__OPENROUTER_API_KEY_PLACEHOLDER__";
        };
      };
    };
  };
}
