# Shared OpenCode profile definitions: single source of truth for profile names
# and their model overrides. Adding a new profile only requires editing this file.

{ config }:

let
  models = import ./_models.nix;

  profiles = [
    {
      name = "opencode";
      model = null;
      alias = "oc";
    }
    {
      name = "opencode-glm";
      model = models.glm;
      alias = "ocglm";
    }
    {
      name = "opencode-gemini";
      model = models.gemini;
      alias = "ocgem";
    }
    {
      name = "opencode-gpt";
      model = models.gpt-default;
      alias = "ocgpt";
    }
    {
      name = "opencode-openrouter";
      model = models.openrouter;
      alias = "ocor";
    }
    {
      name = "opencode-sonnet";
      model = models.claude-sonnet;
      alias = "ocs";
    }
    {
      name = "opencode-zen";
      model = models.zen;
      alias = "oczen";
    }
  ];

  names = map (p: p.name) profiles;
  configPath = name: "${config.xdg.configHome}/${name}/opencode.json";
in
{
  inherit names configPath profiles;
}
