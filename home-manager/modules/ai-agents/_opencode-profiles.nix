# Shared OpenCode profile names and config paths.
{ config }:

let
  names = [
    "opencode"
    "opencode-glm"
    "opencode-gemini"
    "opencode-gpt"
    "opencode-sonnet"
  ];
  configPath = name: "${config.home.homeDirectory}/.config/${name}/opencode.json";
in
{
  inherit names configPath;
}
