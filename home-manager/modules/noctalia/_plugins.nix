# Plugin registry for Noctalia Shell.
# Categorized by activation behavior:
#   - all: every plugin deployed via home.file symlinks
#   - needsBackup: plugins with mutable settings.json to preserve across HM switches
#   - needsMaterialization: plugins requiring symlink-to-directory conversion on activation
{
  all = [
    "model-usage"
    "keybind-cheatsheet"
    "mawaqit"
    "browser-launcher"
  ];

  needsBackup = [
    "mawaqit"
    "model-usage"
  ];

  needsMaterialization = [
    "keybind-cheatsheet"
    "mawaqit"
    "model-usage"
  ];
}
