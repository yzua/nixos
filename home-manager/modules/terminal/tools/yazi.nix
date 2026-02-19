# Yazi terminal file manager with image preview and Lua plugins.

{
  constants,
  pkgs,
  ...
}:

{
  # file package provided by home.packages (utilities.nix)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    plugins = {
      inherit (pkgs.yaziPlugins) git diff full-border;
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
    '';

    keymap.manager.prepend_keymap = [
      {
        on = [
          "g"
          "d"
        ];
        run = "plugin diff";
        desc = "Diff selected file with hovered file";
      }
    ];

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
        show_symlink = true;
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
        image_filter = "triangle";
        image_quality = 75;
      };

      opener = {
        edit = [
          {
            run = ''${constants.editor} "$@"'';
            block = false;
            desc = "Open in Zed";
          }
        ];
        open = [
          {
            run = ''xdg-open "$@"'';
            desc = "Open with system default";
          }
        ];
      };

      plugin.prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
    };
  };
}
