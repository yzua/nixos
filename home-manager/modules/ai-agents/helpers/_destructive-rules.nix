# Shared destructive command definitions used across agent configurations.
# Single source of truth — all agents reference this to generate their
# agent-specific deny/block rules from the same canonical command list.

let
  # Destructive system commands — blocked across all agents.
  systemCommands = [
    "rm -rf /"
    "rm -rf ~"
    "rm -rf /*"
    "mkfs"
    "dd"
    "shutdown"
    "reboot"
    "poweroff"
  ];

  # Destructive git commands — blocked across all agents.
  gitCommands = [
    "git push --force"
    "git push -f"
    "git reset --hard"
    "git clean -fd"
    "git clean -fdx"
  ];

  # Map a canonical command to its hook-specific grep -E regex pattern.
  # rm variants need [[:space:]]+ for variable spacing and path-aware matching.
  # dd requires if= argument to avoid false positives on bare dd.
  # Simple commands and git commands match literally.
  toHookPattern =
    cmd:
    if cmd == "rm -rf /" then
      "rm[[:space:]]+-rf[[:space:]]+/( |$)"
    else if cmd == "rm -rf ~" then
      "rm[[:space:]]+-rf[[:space:]]+~"
    else if cmd == "rm -rf /*" then
      "rm[[:space:]]+-rf[[:space:]]+/\\*"
    else if cmd == "dd" then
      "dd[[:space:]]+if="
    else
      cmd;
in
{
  inherit systemCommands gitCommands;

  # Generate Claude permission deny rules: "Bash(prefix*)" glob patterns.
  mkClaudeDenyRules = commands: map (cmd: "Bash(${cmd}*)") commands;

  # Generate Gemini TOML deny rules from command list.
  mkGeminiDenyRules =
    commands:
    builtins.concatStringsSep "\n\n" (
      map (cmd: ''
        [[rule]]
        toolName = "run_shell_command"
        commandPrefix = "${cmd}"
        decision = "deny"
        priority = 900'') commands
    );

  # Generate a grep -E regex alternation for PreToolUse hook matching.
  # Each canonical command is mapped to its hook-specific regex form.
  mkHookRegex = commands: builtins.concatStringsSep "|" (map toHookPattern commands);
}
