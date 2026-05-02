 # OpenCode agent definitions and permission policies.

{ models ? null }:

let
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

  yoloPermission = {
    read = "allow";
    edit = "allow";
    glob = "allow";
    grep = "allow";
    list = "allow";
    bash = "allow";
    task = "allow";
    external_directory = "allow";
    todowrite = "allow";
    question = "allow";
    webfetch = "allow";
    websearch = "allow";
    codesearch = "allow";
    lsp = "allow";
    doom_loop = "allow";
    skill = "allow";
  };

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
  inherit readOnlyPermission yoloPermission;

  # agents = {
    plan = {
     model = models.claude-sonnet;
     description = "Primary planning agent for specs, decomposition, and research-backed execution plans.";
     mode = "primary";
     steps = 12;
     temperature = 0.1;
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
     temperature = 0.2;
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
     temperature = 0.1;
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
     temperature = 0.2;
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
     temperature = 0.1;
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
     temperature = 0.1;
     permission = yoloPermission;
     prompt = ''
       Optimize runtime performance with evidence, not guesses.
       Measure the real hot path first, prefer the highest-impact low-risk change, and preserve correctness plus repository conventions.
       Report before-and-after performance evidence, correctness validation, and any tradeoffs left in place.
'';
    };
# };
}
