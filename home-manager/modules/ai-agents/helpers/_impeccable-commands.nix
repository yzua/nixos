# Impeccable skill command definitions and text renderer.
# Separated from files.nix for clearer ownership: this is command content
# generation, not file placement.

let
  impeccableCommandDefs = [
    {
      name = "teach-impeccable";
      description = "One-time setup: gather design context, save to config";
    }
    {
      name = "audit";
      description = "Run technical quality checks";
    }
    {
      name = "critique";
      description = "UX design review";
    }
    {
      name = "normalize";
      description = "Align with design system standards";
    }
    {
      name = "polish";
      description = "Final pass before shipping";
    }
    {
      name = "distill";
      description = "Strip to essence";
    }
    {
      name = "clarify";
      description = "Improve unclear UX copy";
    }
    {
      name = "optimize";
      description = "Performance improvements";
    }
    {
      name = "harden";
      description = "Error handling, i18n, edge cases";
    }
    {
      name = "animate";
      description = "Add purposeful motion";
    }
    {
      name = "colorize";
      description = "Introduce strategic color";
    }
    {
      name = "bolder";
      description = "Amplify boring designs";
    }
    {
      name = "quieter";
      description = "Tone down overly bold designs";
    }
    {
      name = "delight";
      description = "Add moments of joy";
    }
    {
      name = "extract";
      description = "Pull into reusable components";
    }
    {
      name = "adapt";
      description = "Adapt for different devices";
    }
    {
      name = "onboard";
      description = "Design onboarding flows";
    }
    {
      name = "typeset";
      description = "Fix font choices, hierarchy, sizing";
    }
    {
      name = "arrange";
      description = "Fix layout, spacing, visual rhythm";
    }
    {
      name = "overdrive";
      description = "Add technically extraordinary effects";
    }
  ];

  mkImpeccableCommandText = cmd: ''
    ---
    description: ${cmd.description}
    ---

    Use the `${cmd.name}` skill from the installed Impeccable pack.

    Target: $ARGUMENTS
    If no target is provided, apply it to the most relevant current UI surface.
  '';
in
{
  inherit impeccableCommandDefs mkImpeccableCommandText;
}
