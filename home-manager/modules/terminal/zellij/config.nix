# Zellij settings and keybinds.

{ pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    # HM's zellij attach -c breaks with multiple sessions; auto-start is in zsh initContent
    enableZshIntegration = false;

    settings = {
      theme = "default"; # Stylix generates ~/.config/zellij/themes/stylix.kdl defining "default"
      default_shell = "${pkgs.zsh}/bin/zsh";
      default_layout = "default";

      pane_frames = false;
      simplified_ui = false;
      styled_underlines = true;
      auto_layout = true;
      mouse_mode = true;

      copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      copy_on_select = true;

      scroll_buffer_size = 50000;
      scrollback_editor = "${pkgs.neovim}/bin/nvim";

      session_serialization = true;
      pane_viewport_serialization = true;

      on_force_close = "quit";
      show_startup_tips = false;
      show_release_notes = false;
    };

    extraConfig = ''
      ui {
        pane_frames {
          rounded_corners true
          hide_session_name true
        }
      }

      plugins {
        autolock location="file:~/.config/zellij/plugins/zellij-autolock.wasm" {
          is_enabled true
          triggers "nvim|vim|git|fzf|zoxide|atuin|lazygit"
          reaction_seconds "0.3"
          print_to_log false
        }
      }

      load_plugins {
        autolock
      }

      keybinds {
        unbind "Ctrl q"

        scroll {
          bind "Esc" "q" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          bind "Ctrl f" "PageDown" { PageScrollDown; }
          bind "Ctrl b" "PageUp" { PageScrollUp; }
          bind "g" { ScrollToTop; }
          bind "G" { ScrollToBottom; }
          bind "e" { EditScrollback; SwitchToMode "Normal"; }
          bind "/" "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
        }

        search {
          bind "Esc" "q" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "d" "Ctrl d" { HalfPageScrollDown; }
          bind "u" "Ctrl u" { HalfPageScrollUp; }
          bind "Ctrl f" "PageDown" { PageScrollDown; }
          bind "Ctrl b" "PageUp" { PageScrollUp; }
          bind "n" { Search "down"; }
          bind "N" { Search "up"; }
          bind "c" { SearchToggleOption "CaseSensitivity"; }
          bind "w" { SearchToggleOption "Wrap"; }
          bind "o" { SearchToggleOption "WholeWord"; }
        }

        entersearch {
          bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
          bind "Enter" { SwitchToMode "Search"; }
        }

        session {
          bind "Ctrl o" "Esc" { SwitchToMode "Normal"; }
          bind "d" { Detach; }
        }

        shared_except "scroll" "locked" "entersearch" "search" {
          bind "Ctrl s" { SwitchToMode "Scroll"; }
        }

        shared_except "locked" "renametab" "renamepane" "entersearch" {
          bind "Alt h" { MoveFocusOrTab "Left"; }
          bind "Alt j" { MoveFocus "Down"; }
          bind "Alt k" { MoveFocus "Up"; }
          bind "Alt l" { MoveFocusOrTab "Right"; }

          bind "Alt 1" { GoToTab 1; SwitchToMode "Normal"; }
          bind "Alt 2" { GoToTab 2; SwitchToMode "Normal"; }
          bind "Alt 3" { GoToTab 3; SwitchToMode "Normal"; }
          bind "Alt 4" { GoToTab 4; SwitchToMode "Normal"; }
          bind "Alt 5" { GoToTab 5; SwitchToMode "Normal"; }
          bind "Alt 6" { GoToTab 6; SwitchToMode "Normal"; }
          bind "Alt 7" { GoToTab 7; SwitchToMode "Normal"; }
          bind "Alt 8" { GoToTab 8; SwitchToMode "Normal"; }
          bind "Alt 9" { GoToTab 9; SwitchToMode "Normal"; }

          bind "Alt n" { NewPane; }
          bind "Alt s" { NewPane "Down"; SwitchToMode "Normal"; }
          bind "Alt v" { NewPane "Right"; SwitchToMode "Normal"; }
          bind "Alt x" { CloseFocus; SwitchToMode "Normal"; }
          bind "Alt z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
          bind "Alt w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
          bind "Alt f" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }

          bind "Alt Enter" { NewTab; SwitchToMode "Normal"; }
          bind "Alt q" { CloseTab; SwitchToMode "Normal"; }
          bind "Alt 0" { ToggleTab; }
          bind "Alt ." { MoveTab "Right"; }
          bind "Alt ," { MoveTab "Left"; }

          bind "Alt =" { Resize "Increase"; }
          bind "Alt -" { Resize "Decrease"; }

          bind "Alt [" { PreviousSwapLayout; }
          bind "Alt ]" { NextSwapLayout; }

          bind "Alt e" { EditScrollback; SwitchToMode "Normal"; }

          bind "Alt o" {
            LaunchOrFocusPlugin "zellij:session-manager" {
              floating true
              move_to_focused_tab true
            }
          }

          bind "Alt p" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/monocle.wasm" {
              floating true
            }
          }
          bind "Alt r" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/room.wasm" {
              floating true
              ignore_case true
            }
          }
          bind "Alt b" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/harpoon.wasm" {
              floating true
            }
          }
          bind "Alt /" {
            LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-forgot.wasm" {
              floating true
              "LOAD_ZELLIJ_BINDINGS" "true"
            }
          }
          bind "Alt m" {
            LaunchPlugin "file:~/.config/zellij/plugins/multitask.wasm" {
              floating false
            }
          }
        }
      }
    '';
  };
}
