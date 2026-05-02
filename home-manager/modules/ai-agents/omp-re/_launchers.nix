# oh-my-pi RE agent launcher wrappers.
# Generates opiare (android-re) and opiwre (web-re) scripts that inject
# the RE system prompt via omp's --append-system-prompt flag.
# Loads the Z.AI API key from sops into ZAI_API_KEY env var for models.yml routing.

{ pkgs }:

let
  mkOmpReLauncher =
    { name, promptFile }:
    pkgs.writeShellScriptBin name ''
      ZAI_API_KEY="$(cat /run/secrets/zai_api_key)" \
      exec omp --append-system-prompt "$(cat ${promptFile})" "$@"
    '';
in
[
  (mkOmpReLauncher {
    name = "opiare";
    promptFile = "$HOME/.config/omp/android-re-prompt.txt";
  })
  (mkOmpReLauncher {
    name = "opiwre";
    promptFile = "$HOME/.config/omp/web-re-prompt.txt";
  })
]
