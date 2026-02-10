# Atuin shell history replacement with full-text search and cross-machine sync.

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "directory";

      style = "compact";
      inline_height = 20;
      show_preview = true;
      show_help = true;

      history_filter = [
        "^ls"
        "^cd"
        "^exit"
        "^clear"
      ];

      # Sync disabled to prevent accidental activation
      auto_sync = false;
      secrets_filter = true;
      keymap_mode = "auto";
    };

    daemon.enable = false;
  };
}
