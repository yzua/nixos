# Main Niri compositor settings.

{
  constants,
  pkgs,
  ...
}:

let
  workspaceName = {
    browser = "󰖟 browser";
    editor = "󰨞 editor";
    social = "󰍡 social";
    media = "󰎆 media";
    vpn = "󰦝 vpn";
  };
  mkSpring =
    {
      dampingRatio,
      stiffness,
      epsilon,
    }:
    {
      damping-ratio = dampingRatio;
      inherit stiffness epsilon;
    };
  mkBackdropRule = namespace: {
    matches = [ { inherit namespace; } ];
    place-within-backdrop = true;
  };
in

{
  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;
    screenshot-path = "~/Screens/screenshot-%Y-%m-%d-%H-%M-%S.png";

    workspaces = {
      "01-browser" = {
        name = workspaceName.browser; # nf-md-web
      };
      "02-code" = {
        name = workspaceName.editor; # nf-md-code-braces
      };
      "03-social" = {
        name = workspaceName.social; # nf-md-chat
      };
      "04-media" = {
        name = workspaceName.media; # nf-md-music
      };
      "05-vpn" = {
        name = workspaceName.vpn; # nf-md-shield-lock
      };
    };

    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      # QT_QPA_PLATFORM is set globally in home.nix sessionVariables
      QT_STYLE_OVERRIDE = "fusion";
      XDG_SCREENSHOTS_DIR = "$HOME/Screens";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keepassxc-ssh-agent.socket";
    };

    spawn-at-startup = [
      { argv = [ "${pkgs.xwayland-satellite}/bin/xwayland-satellite" ]; }
      { argv = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
      { argv = [ "${pkgs.noctalia-shell}/bin/noctalia-shell" ]; }
      { argv = [ "${pkgs.keepassxc}/bin/keepassxc" ]; }
      { argv = [ "${pkgs.mullvad-vpn}/bin/mullvad-vpn" ]; }
      {
        argv = [
          "${pkgs.wl-clipboard}/bin/wl-paste"
          "--type"
          "text"
          "--watch"
          "${pkgs.cliphist}/bin/cliphist"
          "store"
        ];
      }
      {
        argv = [
          "${pkgs.wl-clipboard}/bin/wl-paste"
          "--type"
          "image"
          "--watch"
          "${pkgs.cliphist}/bin/cliphist"
          "store"
        ];
      }
      {
        argv = [
          "${pkgs.wl-clip-persist}/bin/wl-clip-persist"
          "--clipboard"
          "regular"
        ];
      }

      { argv = [ "/home/${constants.user.handle}/.local/bin/librewolf-personal" ]; }
      { argv = [ "${constants.editor}" ]; }
      {
        argv = [
          "${constants.terminal}"
          "-e"
          "${pkgs.zellij}/bin/zellij"
          "attach"
          "--create"
          "main"
        ];
      }
      { argv = [ "${pkgs.vesktop}/bin/vesktop" ]; }
      { argv = [ "${pkgs.telegram-desktop}/bin/Telegram" ]; }
    ];

    animations = {
      slowdown = 1.0;

      workspace-switch.kind.spring = mkSpring {
        dampingRatio = 1.0;
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

      horizontal-view-movement.kind.spring = mkSpring {
        dampingRatio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      window-movement.kind.spring = mkSpring {
        dampingRatio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      window-resize.kind.spring = mkSpring {
        dampingRatio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };

      config-notification-open-close.kind.spring = mkSpring {
        dampingRatio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };

    layer-rules = [
      (mkBackdropRule "^noctalia-wallpaper")
      (mkBackdropRule "^noctalia-overview")
    ];

    gestures.hot-corners.enable = false;

    # Required for Noctalia notification actions and window activation
    debug.honor-xdg-activation-with-invalid-serial = [ ];
  };
}
