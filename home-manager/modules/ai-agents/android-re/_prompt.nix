{
  lib,
}:

let
  repoRoot = ../../../../.;
  promptSourceDir = repoRoot + "/home-manager/modules/ai-agents/android-re/prompts";
  promptEntries = builtins.readDir promptSourceDir;
  markdownFiles = builtins.filter (
    name: promptEntries.${name} == "regular" && lib.hasSuffix ".md" name
  ) (builtins.attrNames promptEntries);
  renderPromptFile =
    name:
    let
      path = promptSourceDir + "/${name}";
    in
    ''
      ## ${name}
      Source: ${toString path}

      ${builtins.readFile path}
    '';
in
{
  inherit markdownFiles;
  promptSourceDir = toString promptSourceDir;
  promptText = lib.concatMapStringsSep "\n\n" renderPromptFile markdownFiles;
}
