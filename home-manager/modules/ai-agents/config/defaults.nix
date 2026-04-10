# Base AI agent defaults: enablement, shared instructions, and skill sets.

_:

let
  skillDefs = import ./_skills.nix;
in
{
  programs.aiAgents = {
    enable = true;
    globalInstructions = builtins.readFile ./global-instructions.md;

    inherit (skillDefs) skills omitSkills;
  };
}
