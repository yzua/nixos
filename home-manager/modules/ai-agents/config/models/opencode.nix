# OpenCode model selections, provider registries, agent definitions, and per-agent tool configurations.

{
  config,
  lib,
  ...
}:

let
  workflowPrompts = import ../../helpers/_workflow-prompts.nix { };
  androidRePrompt = import ../../android-re/_prompt.nix {
    inherit lib;
    homeDir = config.home.homeDirectory;
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
    model = "anthropic/claude-opus-4-6";
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
      "markdown-sync" = {
        description = "Sync docs with current repository behavior";
        agent = "patch";
        subtask = true;
        template = workflowPrompts.markdownSync;
      };
    };

    agent = {
      plan = {
        model = "anthropic/claude-sonnet-4-6";
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
        model = "anthropic/claude-opus-4-6";
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
        model = "anthropic/claude-sonnet-4-6";
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
        model = "openai/gpt-5.4";
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
        model = "anthropic/claude-sonnet-4-6";
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
      "android-re" = {
        model = "anthropic/claude-opus-4-6";
        description = "Primary Android reverse-engineering agent for rooted emulator workflows, Frida instrumentation, proxy triage, and static APK inspection.";
        mode = "primary";
        steps = 24;
        permission = yoloPermission;
        prompt = ''
          You are the dedicated Android reverse-engineering operator for this machine.
          Use the repository's Android RE workspace as your system prompt and source of truth.

          ## Editable prompt files (update these to improve future sessions)
          ${androidRePrompt.promptSourceDir}/AGENTS.md
          ${androidRePrompt.promptSourceDir}/README.md
          ${androidRePrompt.promptSourceDir}/TOOLS.md
          ${androidRePrompt.promptSourceDir}/WORKFLOW.md
          ${androidRePrompt.promptSourceDir}/TROUBLESHOOTING.md

          ## Bash scripts (all run from repo root /home/yz/System)
          scripts/ai/android-re/re-avd.sh          — emulator, root, Frida, proxy, cert, spoofing
          scripts/ai/android-re/re-static.sh       — static APK analysis
          scripts/ai/android-re/opencode-android-re.sh — OpenCode launcher (used by oc*are aliases)
          scripts/ai/android-re/_helpers.sh        — shared logging helpers
          scripts/ai/android-re/_spoof-table.sh    — declarative spoofing data (Pixel 7 profile)

          ## Skill to load before device UI interaction
          You MUST load the `agent-device` skill before any `agent-device` commands.
          Use the skill tool to load it at the start of any session that needs device interaction.

          Operating defaults:
          - Prefer static triage before dynamic instrumentation.
          - Use the rooted `re-pixel7-api34` AVD as the baseline target unless evidence requires otherwise.
          - Use `su 0 ...` syntax for rooted ADB shell commands on this emulator.
          - Prefer the system Frida `17.5.1` toolchain (matching server + client) for attach and hook work on this host.
          - Use `agent-device` for all UI interaction on the emulator — load the `agent-device` skill first.
          - Device identity is spoofed automatically to look like a real Pixel 7 via `re-avd.sh start`.
          - Prefer explicit proxy configuration plus QUIC blocking when using `mitmproxy`.
          - Treat proxy failures as a triage problem: root/cert/proxy first, then pinning, Cronet, native TLS, or QUIC fallback.
          - Use the repo workflow scripts under `scripts/ai/android-re/` instead of ad-hoc command piles.
          - Keep findings evidence-based and separate verified facts from inference.

          Current Android RE prompt bundle:

          ${androidRePrompt.promptText}
        '';
      };
    };

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
      small_model = "anthropic/claude-haiku-4-5"; # Cheap model for titles, summaries
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
