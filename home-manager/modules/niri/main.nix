# Main Niri compositor settings.

{
  constants,
  ...
}:

{
  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;
    screenshot-path = "~/Screens/screenshot-%Y-%m-%d-%H-%M-%S.png";

    workspaces = {
      "01-browser" = {
        name = "󰖟 browser"; # nf-md-web
      };
      "02-code" = {
        name = "󰨞 editor"; # nf-md-code-braces
      };
      "03-social" = {
        name = "󰍡 social"; # nf-md-chat
      };
      "04-media" = {
        name = "󰎆 media"; # nf-md-music
      };
      "05-vpn" = {
        name = "󰦝 vpn"; # nf-md-shield-lock
      };
    };

    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      # QT_QPA_PLATFORM is set globally in home.nix sessionVariables
      QT_STYLE_OVERRIDE = "kvantum";
      XDG_SCREENSHOTS_DIR = "$HOME/Screens";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keepassxc-ssh-agent.socket";
    };

    spawn-at-startup = [
      { argv = [ "xwayland-satellite" ]; }
      { argv = [ "noctalia-shell" ]; }
      { argv = [ "keepassxc" ]; }
      { argv = [ "mullvad-vpn" ]; }
      {
        argv = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        argv = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        argv = [
          "wl-clip-persist"
          "--clipboard"
          "regular"
        ];
      }

      { argv = [ "brave" ]; }
      { argv = [ "${constants.editor}" ]; }
      { argv = [ "${constants.terminal}" ]; }
      { argv = [ "vesktop" ]; }
      { argv = [ "telegram-desktop" ]; }
      { argv = [ "youtube-music" ]; }
    ];

    input = {
      keyboard = {
        xkb = {
          inherit (constants.keyboard) layout variant;
          options = "${constants.keyboard.options},${constants.keyboardNiriExtra}";
        };
        repeat-rate = 25;
        repeat-delay = 600;
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = true;
        dwtp = true; # Disable-while-trackpointing (ThinkPad essential)
        click-method = "clickfinger"; # Two-finger = right-click
        accel-profile = "adaptive"; # Natural acceleration curve
      };
      trackpoint = {
        accel-speed = 0.4; # Range: -1.0 to 1.0
        accel-profile = "flat"; # No acceleration curve, raw input
      };
      mouse = {
        accel-speed = 0.0;
      };

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
      warp-mouse-to-focus.enable = true;
      workspace-auto-back-and-forth = true;
    };

    layout = {
      gaps = 8;
      center-focused-column = "on-overflow";

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];

      default-column-width = {
        proportion = 0.5;
      };

      focus-ring.enable = false; # Stylix sets border colors instead

      border = {
        enable = true;
        width = 2;
      };

      struts = { };

      background-color = "transparent"; # Noctalia wallpaper shows through
    };

    animations = {
      slowdown = 1.0;

      workspace-switch.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 1000;
        epsilon = 0.0001;
      };

      window-open.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-expo";
      };

      window-close.kind.easing = {
        duration-ms = 150;
        curve = "ease-out-quad";
      };

      horizontal-view-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      window-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      window-resize.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      config-notification-open-close.kind.spring = {
        damping-ratio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };

    window-rules =
      let
        r = 10.0; # Corner radius
      in
      [
        {
          geometry-corner-radius = {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
        }

        {
          matches = [ { app-id = "^io\\.github\\.celluloid_player\\.Celluloid$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^io\\.bassi\\.Amberol$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^imv$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^showmethekey-gtk$"; } ];
          open-floating = true;
        }

        {
          matches = [
            {
              app-id = "^org\\.telegram\\.desktop$";
              title = "^Media viewer$";
            }
          ];
          open-floating = true;
        }

        {
          matches = [ { app-id = "^org\\.gnome\\.NautilusPreviewer$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^(pwvucontrol|nm-connection-editor|blueman-manager)$"; } ];
          open-floating = true;
        }
        {
          matches = [
            { app-id = "^org\\.gnome\\.Calculator$"; }
            { app-id = "^qalculate-gtk$"; }
          ];
          open-floating = true;
        }

        {
          matches = [ { app-id = "^org\\.keepassxc\\.KeePassXC$"; } ];
          open-on-workspace = "󰦝 vpn";
          open-floating = true;
        }
        {
          matches = [
            { app-id = "^xdg-desktop-portal-gtk$"; }
            { app-id = "^xdg-desktop-portal-gnome$"; }
          ];
          open-floating = true;
        }

        {
          matches = [ { title = "^Picture-in-Picture$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^scratchpad$"; } ];
          open-floating = true;
        }
        {
          matches = [ { app-id = "^(${constants.terminalAppId}|kitty|foot)$"; } ];
          opacity = 0.92;
        }
        {
          matches = [ { app-id = "^brave"; } ];
        }

        {
          matches = [ { app-id = "^1password$"; } ];
          block-out-from = "screen-capture";
        }

        {
          matches = [ { app-id = "^xwaylandvideobridge$"; } ];
          opacity = 0.0;
          block-out-from = "screen-capture";
        }

        {
          matches = [ { is-floating = true; } ];
          shadow.enable = true;
        }
        {
          matches = [ { is-active = false; } ];
          opacity = 0.95;
        }
        {
          matches = [ { title = "^Picture-in-Picture$"; } ];
          default-floating-position = {
            x = 32;
            y = 32;
            relative-to = "bottom-right";
          };
          default-column-width.fixed = 480;
          default-window-height.fixed = 270;
        }

        {
          matches = [ { app-id = "^scratchpad$"; } ];
          default-floating-position = {
            x = 0;
            y = 0;
            relative-to = "top";
          };
          default-column-width = {
            proportion = 0.6;
          };
          default-window-height = {
            proportion = 0.4;
          };
        }

        {
          matches = [ { app-id = "^(brave|firefox|chromium)"; } ];
          scroll-factor = 0.75;
        }

        # Workspace assignments
        {
          matches = [ { app-id = "^brave-browser$"; } ];
          open-on-workspace = "󰖟 browser";
          default-column-width.proportion = 1.0;
        }

        {
          matches = [ { app-id = "^(${constants.editorAppId})$"; } ];
          open-on-workspace = "󰨞 editor";
        }

        {
          matches = [ { app-id = "^(${constants.terminalAppId})$"; } ];
          excludes = [ { app-id = "^scratchpad$"; } ];
          open-on-workspace = "󰨞 editor";
        }

        {
          matches = [ { app-id = "^vesktop$"; } ];
          open-on-workspace = "󰍡 social";
        }

        {
          matches = [ { app-id = "^org\\.telegram\\.desktop$"; } ];
          excludes = [
            {
              app-id = "^org\\.telegram\\.desktop$";
              title = "^Media viewer$";
            }
          ];
          open-on-workspace = "󰍡 social";
        }

        {
          matches = [ { app-id = "^youtube-music$"; } ];
          open-on-workspace = "󰎆 media";
          default-column-width.proportion = 1.0;
        }

        {
          matches = [ { app-id = "^FreeTube$"; } ];
          open-on-workspace = "󰎆 media";
        }

        {
          matches = [ { app-id = "^Mullvad VPN$"; } ];
          open-on-workspace = "󰦝 vpn";
          open-floating = true;
        }
      ];

    layer-rules = [
      {
        matches = [ { namespace = "^noctalia-wallpaper"; } ];
        place-within-backdrop = true;
      }
      {
        matches = [ { namespace = "^noctalia-overview"; } ];
        place-within-backdrop = true;
      }
    ];

    gestures.hot-corners.enable = false;

    # Required for Noctalia notification actions and window activation
    debug.honor-xdg-activation-with-invalid-serial = [ ];
  };
}
