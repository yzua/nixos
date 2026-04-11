{
  lib,
}:

let
  # Read files from the Nix store copy (needed for builtins.readFile)
  repoRoot = ../../../../.;
  promptSourceDir = repoRoot + "/home-manager/modules/ai-agents/android-re/prompts";
  promptEntries = builtins.readDir promptSourceDir;
  markdownFiles = builtins.filter (
    name: promptEntries.${name} == "regular" && lib.hasSuffix ".md" name
  ) (builtins.attrNames promptEntries);

  # The real filesystem path the agent should use for editing.
  # Nix paths copy into /nix/store (read-only), so we hardcode the repo location
  # so the agent can actually edit these files.
  realRepoRoot = "/home/yz/System";
  realPromptSourceDir = "${realRepoRoot}/home-manager/modules/ai-agents/android-re/prompts";

  renderPromptFile =
    name:
    let
      path = promptSourceDir + "/${name}";
    in
    ''
      ## ${name}
      Editable path: ${realPromptSourceDir}/${name}

      ${builtins.readFile path}
    '';
in
{
  inherit markdownFiles;
  promptSourceDir = realPromptSourceDir;
  promptText = lib.concatMapStringsSep "\n\n" renderPromptFile markdownFiles;
}
