# Ghostty terminal emulator configuration.

{
  constants,
  lib,
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;

    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = {
      font-family = constants.font.monoNerd;
      font-family-bold = constants.font.monoNerd;
      font-family-italic = constants.font.monoNerd;
      font-family-bold-italic = constants.font.monoNerd;
      font-size = lib.mkForce constants.font.size;
      font-thicken = true;
      adjust-cell-height = "0%";

      # theme is managed by Stylix (stylix.targets.ghostty.enable = true)

      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;
      window-decoration = false; # Niri handles decorations
      window-title-font-family = constants.font.monoNerd;
      gtk-single-instance = true;

      cursor-style = "block";
      cursor-style-blink = true;
      cursor-color = constants.color.yellow_dim;

      copy-on-select = "clipboard";
      selection-invert-fg-bg = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-paste-protection = true;
      clipboard-trim-trailing-spaces = true;

      mouse-hide-while-typing = true;
      mouse-scroll-multiplier = 1;

      scrollback-limit = 50000;

      link-url = true;

      shell-integration = "zsh";
      shell-integration-features = "cursor,sudo,title";

      bold-is-bright = false;
      gtk-tabs-location = "hidden"; # Zellij handles multiplexing

      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+0=reset_font_size"
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"
        "shift+home=scroll_to_top"
        "shift+end=scroll_to_bottom"
        "ctrl+shift+n=new_window"
        "ctrl+l=text:\\x0c"
        "ctrl+shift+i=inspector:toggle"
      ];

      confirm-close-surface = false;
      auto-update = "off"; # Managed by Nix
    };
  };
}
