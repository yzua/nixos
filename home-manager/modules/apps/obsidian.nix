# Obsidian Markdown notes app configuration.
_:

{
  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    genericName = "Markdown Notes";
    comment = "Markdown knowledge base";
    exec = "obsidian %U";
    icon = "obsidian";
    terminal = false;
    categories = [
      "Office"
      "Utility"
    ];
    mimeType = [
      "text/markdown"
      "x-scheme-handler/obsidian"
    ];
  };

  # Baseline global defaults; vault-specific preferences remain user-managed.
  xdg.configFile."obsidian/obsidian.json".text = builtins.toJSON {
    alwaysUpdateLinks = true;
    newFileLocation = "current";
    newLinkFormat = "relative";
    promptDelete = false;
    showLineNumber = true;
    trashOption = "local";
    useMarkdownLinks = true;
  };
}
