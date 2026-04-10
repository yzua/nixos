{
  config,
  lib,
  pkgs,
}:
let
  launcherScript = "${config.home.homeDirectory}/System/scripts/ai/android-re/opencode-android-re.sh";
  promptSourceDir = "${config.home.homeDirectory}/System/home-manager/modules/ai-agents/android-re/prompts";
  mkAndroidReLauncher =
    {
      name,
      profile,
    }:
    pkgs.writeShellScriptBin name ''
      ANDROID_RE_PROMPT_SOURCE_DIR=${lib.escapeShellArg promptSourceDir} \
        ANDROID_RE_OPENCODE_PROFILE=${lib.escapeShellArg profile} \
        exec ${launcherScript} "$@"
    '';
in
map mkAndroidReLauncher [
  {
    name = "ocare";
    profile = "default";
  }
  {
    name = "ocglmare";
    profile = "glm";
  }
  {
    name = "ocgemare";
    profile = "gemini";
  }
  {
    name = "ocgptare";
    profile = "gpt";
  }
  {
    name = "ocorare";
    profile = "openrouter";
  }
  {
    name = "ocsare";
    profile = "sonnet";
  }
  {
    name = "oczenare";
    profile = "zen";
  }
]
