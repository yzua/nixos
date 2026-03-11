# Shared OpenCode profile names and config paths.
{ config }:

let
  names = [
    "opencode"
    "opencode-glm"
    "opencode-gemini"
    "opencode-gpt"
    "opencode-sonnet"
    "opencode-zen"
  ];
  configPath = name: "${config.xdg.configHome}/${name}/opencode.json";
in
{
  inherit names configPath;
}
