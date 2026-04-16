# Zellij layout definitions (default, dev, ai, monitoring).
# deadnix false-positive: constants IS used in zjstatusConfig string interpolation.
# deadnix: hide

{
  config,
  constants,
  pkgs,
  ...
}:

let
  zjstatusConfig = ''
    pane size=1 borderless=true {
      plugin location="file:~/.config/zellij/plugins/zjstatus.wasm" {
        format_left   "{mode}{tabs}"
        format_center ""
        format_right  "#[bg=${constants.color.bg_soft},fg=${constants.color.bg0}]#[bg=${constants.color.bg0},fg=${constants.color.gray}]  {session} #[fg=${constants.color.gray}]   {datetime} "
        format_space  "#[bg=${constants.color.bg_soft}]"
        format_hide_on_overlength "true"
        format_precedence "lrc"

        border_enabled  "false"

        hide_frame_for_single_pane "true"

        mode_normal        ""
        mode_locked        "#[bg=${constants.color.yellow_dim},fg=${constants.color.bg_hard},bold]  LOCKED #[bg=${constants.color.bg_soft},fg=${constants.color.yellow_dim}]"
        mode_resize        "#[bg=${constants.color.blue},fg=${constants.color.bg_hard},bold] 󰩨 RESIZE #[bg=${constants.color.bg_soft},fg=${constants.color.blue}]"
        mode_pane          "#[bg=${constants.color.green},fg=${constants.color.bg_hard},bold]  PANE #[bg=${constants.color.bg_soft},fg=${constants.color.green}]"
        mode_tab           "#[bg=${constants.color.blue},fg=${constants.color.bg_hard},bold]  TAB #[bg=${constants.color.bg_soft},fg=${constants.color.blue}]"
        mode_scroll        "#[bg=${constants.color.aqua},fg=${constants.color.bg_hard},bold]  SCROLL #[bg=${constants.color.bg_soft},fg=${constants.color.aqua}]"
        mode_enter_search  "#[bg=${constants.color.purple},fg=${constants.color.bg_hard},bold]  SEARCH #[bg=${constants.color.bg_soft},fg=${constants.color.purple}]"
        mode_search        "#[bg=${constants.color.purple},fg=${constants.color.bg_hard},bold]  SEARCH #[bg=${constants.color.bg_soft},fg=${constants.color.purple}]"
        mode_rename_tab    "#[bg=${constants.color.purple_dim},fg=${constants.color.bg_hard},bold] 󰑕 RENAME #[bg=${constants.color.bg_soft},fg=${constants.color.purple_dim}]"
        mode_rename_pane   "#[bg=${constants.color.purple_dim},fg=${constants.color.bg_hard},bold] 󰑕 RENAME #[bg=${constants.color.bg_soft},fg=${constants.color.purple_dim}]"
        mode_session       "#[bg=${constants.color.red},fg=${constants.color.bg_hard},bold]  SESSION #[bg=${constants.color.bg_soft},fg=${constants.color.red}]"
        mode_move          "#[bg=${constants.color.yellow},fg=${constants.color.bg_hard},bold] 󰆾 MOVE #[bg=${constants.color.bg_soft},fg=${constants.color.yellow}]"
        mode_tmux          "#[bg=${constants.color.aqua_dim},fg=${constants.color.bg_hard},bold]  TMUX #[bg=${constants.color.bg_soft},fg=${constants.color.aqua_dim}]"

        tab_normal              "#[bg=${constants.color.bg0},fg=${constants.color.gray}] {name}{floating_indicator}{fullscreen_indicator} #[bg=${constants.color.bg_soft},fg=${constants.color.bg0}]"
        tab_active              "#[bg=${constants.color.aqua_dim},fg=${constants.color.bg_hard},bold] {name}{floating_indicator}{fullscreen_indicator} #[bg=${constants.color.bg_soft},fg=${constants.color.aqua_dim}]"
        tab_separator           ""
        tab_floating_indicator  " 󰹙"
        tab_fullscreen_indicator " 󰊓"
        tab_sync_indicator      " "

        datetime          " {format} "
        datetime_timezone "Etc/GMT-3"
        datetime_format   "%I:%M %p  %d %b"
      }
    }
  '';

  mkLayoutWithStatus = body: ''
    layout {
      default_tab_template {
        children
        ${zjstatusConfig}
      }

      ${body}
    }
  '';
in
{
  xdg.configFile = {
    "zellij/layouts/default.kdl".text = mkLayoutWithStatus "";

    "zellij/layouts/dev.kdl".text = mkLayoutWithStatus ''
      tab name="code" focus=true {
        pane split_direction="vertical" {
          pane size="75%" command="${pkgs.neovim}/bin/nvim" focus=true
          pane split_direction="horizontal" size="25%" {
            pane name="shell"
            pane name="git" command="${pkgs.lazygit}/bin/lazygit"
          }
        }
      }

      tab name="servers" {
        pane name="server"
      }
    '';

    "zellij/layouts/ai.kdl".text = mkLayoutWithStatus ''
      tab name="agent" focus=true {
        pane split_direction="vertical" {
          pane size="60%" name="claude" command="${config.home.homeDirectory}/.bun/bin/claude"
          pane split_direction="horizontal" {
            pane size="50%" name="logs" command="${pkgs.bash}/bin/bash" {
              args "-c" "tail -f ~/.local/share/opencode/log/*.log ~/.codex/log/*.log 2>/dev/null || echo 'No agent logs yet. Waiting...'; sleep infinity"
            }
            pane name="git" command="${pkgs.lazygit}/bin/lazygit"
          }
        }
      }
    '';

    "zellij/layouts/monitoring.kdl".text = mkLayoutWithStatus ''
      tab name="system" focus=true {
        pane split_direction="horizontal" {
          pane command="${pkgs.btop}/bin/btop"
          pane command="${pkgs.nvtopPackages.full}/bin/nvtop"
        }
      }

      tab name="logs" {
        pane name="journal" command="/run/current-system/sw/bin/journalctl" {
          args "-f"
        }
      }
    '';
  };
}
