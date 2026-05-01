{
  lib,
  pkgs,
  scriptsDir,
}:

let
  launcherScript = "${scriptsDir}/ai/web-re/opencode-web-re.sh";

  mkWebReLauncher =
    {
      name,
      profile,
    }:
    pkgs.writeShellScriptBin name ''
      WEB_RE_OPENCODE_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';

in
map mkWebReLauncher [
  {
    name = "ocwre";
    profile = "default";
  }
  {
    name = "ocglmwre";
    profile = "glm";
  }
  {
    name = "ocgemwre";
    profile = "gemini";
  }
  {
    name = "ocgptwre";
    profile = "gpt";
  }
  {
    name = "ocorwre";
    profile = "openrouter";
  }
  {
    name = "ocswre";
    profile = "sonnet";
  }
  {
    name = "oczenwre";
    profile = "zen";
  }
]
