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
}
