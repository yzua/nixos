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
      {
        argv = [
          "${constants.terminal}"
          "-e"
          "zellij"
          "attach"
          "--create"
          "main"
        ];
      }
      { argv = [ "vesktop" ]; }
      { argv = [ "telegram-desktop" ]; }
      { argv = [ "pear-desktop" ]; }
    ];

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
