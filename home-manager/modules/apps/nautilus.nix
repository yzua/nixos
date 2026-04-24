# Nautilus (GNOME Files) dconf preferences, bookmarks, and document templates.

{
  config,
  constants,
  lib,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  bookmarkDirs = [
    "Documents"
    "Pictures"
    "${constants.paths.screens}"
    "Videos"
    "Music"
    "Downloads"
  ];
  bookmarksText = lib.concatMapStringsSep "\n" (dir: "file://${homeDir}/${dir}") bookmarkDirs;
in

{
  home.file = {
    # Sidebar bookmarks (only existing directories)
    ".config/gtk-3.0/bookmarks" = {
      force = true;
      text = "${bookmarksText}\n";
    };

    # Document templates — populates Nautilus "New Document" context menu
    "Templates/Text File.txt".text = "";
    "Templates/Markdown.md".text = "";
    "Templates/Shell Script.sh".text = ''
      #!/usr/bin/env bash
      set -euo pipefail
    '';
    "Templates/Python Script.py".text = ''
      #!/usr/bin/env python3
    '';
    "Templates/Nix Expression.nix".text = ''
      { pkgs, ... }:

      {
      }
    '';
  };

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view"; # List view for productivity
      show-hidden-files = false; # Toggle with Ctrl+H when needed
      show-delete-permanently = true; # Show permanent delete in context menu
      show-create-link = true; # Show "Create Link" in context menu
    };

    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "small"; # Compact rows for more content
      use-tree-view = true; # Expandable directory tree in list view
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small"; # Smaller icons for density
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      sort-directories-first = true;
      show-hidden = false;
    };
  };
}
