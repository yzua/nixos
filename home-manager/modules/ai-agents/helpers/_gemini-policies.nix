# Gemini CLI policy rules (TOML format).
# Destructive deny rules are generated from helpers/_destructive-rules.nix.

let
  destructiveRules = import ./_destructive-rules.nix;

  mkAllowRules =
    commands:
    builtins.concatStringsSep "\n\n" (
      map (cmd: ''
        [[rule]]
        toolName = "run_shell_command"
        commandPrefix = "${cmd}"
        decision = "allow"
        priority = 100
        modes = ["plan"]'') commands
    );
in
{
  "00-allow-research.toml" = mkAllowRules [
    "git status"
    "git diff"
    "git log"
    "git show"
    "rg "
    "fd "
    "find "
    "ls"
    "sed "
    "cat "
    "jq "
    "file "
    "strings "
    "readelf "
    "objdump "
    "nm "
    "sqlite3 "
  ];

  "10-deny-destructive.toml" = destructiveRules.mkGeminiDenyRules (
    destructiveRules.systemCommands ++ destructiveRules.gitCommands
  );
}
