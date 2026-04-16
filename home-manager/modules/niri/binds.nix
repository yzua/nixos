# Niri keybindings and custom scripts.

{
  config,
  constants,
  pkgs,
  pkgsStable,
  lib,
  ...
}:

let
  noctalia =
    cmd:
    [
      "${pkgs.bash}/bin/sh"
      "-c"
      ''
        if ! ${config.home.profileDirectory}/bin/noctalia-shell ipc call "$@" >/dev/null 2>&1; then
          ${pkgs.coreutils}/bin/nohup ${config.home.profileDirectory}/bin/noctalia-shell >/dev/null 2>&1 &
          # Wait for shell to initialize before retrying IPC; may need adjustment if startup slows.
          ${pkgs.coreutils}/bin/sleep 0.35
          ${config.home.profileDirectory}/bin/noctalia-shell ipc call "$@" >/dev/null 2>&1 || true
        fi
      ''
      "sh"
    ]
    ++ (lib.splitString " " cmd);

  booksScript = import ./scripts/open-books.nix { inherit pkgsStable; };
  screenshotAnnotate = import ./scripts/screenshot.nix { inherit pkgsStable; };
  colorPicker = import ./scripts/color-picker.nix { inherit pkgsStable; };
  ws = import ./_workspace-names.nix;

  # Shared volume commands — keep Mod+ and XF86Audio step sizes synchronized.
  volumeUp = [
    "${pkgs.wireplumber}/bin/wpctl"
    "set-volume"
    "-l"
    "1"
    "@DEFAULT_AUDIO_SINK@"
    "5%+"
  ];
  volumeDown = [
    "${pkgs.wireplumber}/bin/wpctl"
    "set-volume"
    "@DEFAULT_AUDIO_SINK@"
    "5%-"
  ];
in
{
  home.packages = [
    booksScript
    screenshotAnnotate
    colorPicker
  ];

  programs.niri.settings.binds =
    let
      workspaceTargets = {
        "1" = ws.browser;
        "2" = ws.editor;
        "3" = ws.social;
        "4" = ws.media;
        "5" = 5;
        "6" = ws.android;
        "7" = 7;
        "8" = 8;
        "9" = 9;
      };
      workspaceFocusBinds = lib.mapAttrs' (
        key: workspace:
        lib.nameValuePair "Mod+${key}" {
          action.focus-workspace = workspace;
        }
      ) workspaceTargets;
      workspaceMoveBinds = lib.mapAttrs' (
        key: workspace:
        lib.nameValuePair "Mod+Shift+${key}" {
          action.move-column-to-workspace = workspace;
        }
      ) workspaceTargets;
    in
    {
      # Application shortcuts
      "Mod+Return".action.spawn = [
        "${constants.terminal}"
        "-e"
        "${config.home.profileDirectory}/bin/zellij-main"
      ];
      "Mod+Shift+Return".action.spawn = [ "${constants.terminal}" ];
      "Mod+T".action.spawn = [
        "${constants.terminal}"
        "--class=scratchpad"
      ];
      "Mod+Q".action.close-window = [ ];
      "Mod+F".action.toggle-window-floating = [ ];
      "Mod+M".action.maximize-column = [ ];
      "Mod+Shift+M".action.fullscreen-window = [ ];
      "Mod+C".action.center-column = [ ];
      "Mod+Shift+O".action.toggle-window-rule-opacity = [ ];

      # Noctalia Shell integration
      "Mod+D".action.spawn = noctalia "launcher toggle";
      "Mod+V".action.spawn = noctalia "launcher clipboard";
      "Mod+N".action.spawn = noctalia "notifications toggleHistory";
      "Mod+Home".action.spawn = noctalia "lockScreen lock";
      "Mod+Shift+Escape".action.spawn = noctalia "sessionMenu toggle";
      "Mod+Shift+D".action.spawn = noctalia "darkMode toggle";
      "Mod+Shift+C".action.spawn = noctalia "controlCenter toggle";
      "Mod+Period".action.spawn = noctalia "launcher emoji";
      "Mod+Grave".action.toggle-overview = [ ];
      "Mod+Shift+Equal".action.spawn = noctalia "volume increase";
      "Mod+Shift+Minus".action.spawn = noctalia "volume decrease";
      "Mod+Shift+BackSpace".action.spawn = noctalia "volume muteOutput";
      "Mod+Shift+BracketRight".action.spawn = noctalia "brightness increase";
      "Mod+Shift+BracketLeft".action.spawn = noctalia "brightness decrease";

      # Column management
      "Mod+W".action.toggle-column-tabbed-display = [ ];
      "Mod+Shift+F5".action.switch-preset-window-height = [ ];
      "Mod+Comma".action.consume-or-expel-window-left = [ ];
      "Mod+Slash".action.consume-or-expel-window-right = [ ];
      "Mod+Shift+Home".action.focus-column-first = [ ];
      "Mod+Shift+End".action.focus-column-last = [ ];
      "Mod+Ctrl+Home".action.move-column-to-first = [ ];
      "Mod+Ctrl+End".action.move-column-to-last = [ ];

      "Mod+Ctrl+L".action.spawn = noctalia "lockScreen lock";
      "Mod+Shift+R".action.spawn = [ "/run/current-system/sw/bin/nautilus" ];
      "Mod+B".action.spawn = [
        "${config.home.homeDirectory}/.local/bin/browser-select"
        ""
      ];
      "Mod+Shift+B".action.spawn = [ "${config.home.homeDirectory}/.local/bin/librewolf-i2pd" ];
      "Mod+E".action.spawn = [
        "${pkgsStable.bemoji}/bin/bemoji"
        "-cn"
      ];

      # === Focus Navigation (niri column model) ===
      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Down".action.focus-window-down = [ ];

      # Tab cycling
      "Mod+Tab".action.focus-column-right = [ ];
      "Mod+Shift+Tab".action.focus-column-left = [ ];

      # Recent window navigation (MRU order)
      "Mod+A".action.focus-window-or-workspace-down = [ ];
      "Mod+Shift+A".action.focus-window-or-workspace-up = [ ];

      # Move windows
      "Mod+Shift+Left".action.move-column-left = [ ];
      "Mod+Shift+Right".action.move-column-right = [ ];
      "Mod+Shift+Up".action.move-window-up = [ ];
      "Mod+Shift+Down".action.move-window-down = [ ];

      # Resize
      "Mod+Ctrl+Left".action.set-column-width = "-10%";
      "Mod+Ctrl+Right".action.set-column-width = "+10%";
      "Mod+Ctrl+Up".action.set-window-height = "-10%";
      "Mod+Ctrl+Down".action.set-window-height = "+10%";
      "Mod+Ctrl+R".action.reset-window-height = [ ];

      # Workspace navigation

      "Mod+U".action.focus-workspace-previous = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+Page_Down".action.focus-workspace-down = [ ];

      # Move to workspace

      "Mod+Shift+Page_Up".action.move-column-to-workspace-up = [ ];
      "Mod+Shift+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+Page_Up".action.move-workspace-up = [ ];
      "Mod+Ctrl+Page_Down".action.move-workspace-down = [ ];

      "Mod+R".action.switch-preset-column-width = [ ];

      # Screenshots
      "Print".action.screenshot = [ ];
      "Mod+Print".action.spawn = [
        "${pkgs.bash}/bin/sh"
        "-c"
        "${pkgs.niri}/bin/niri msg action screenshot-screen && ${pkgs.libnotify}/bin/notify-send 'Screenshot' 'Screen captured'"
      ];
      "Mod+Shift+Print".action.spawn = [
        "${pkgs.bash}/bin/sh"
        "-c"
        "${pkgs.niri}/bin/niri msg action screenshot-window && ${pkgs.libnotify}/bin/notify-send 'Screenshot' 'Window captured'"
      ];
      "Mod+Alt+Print".action.spawn = [ "${screenshotAnnotate}/bin/screenshot-annotate" ];
      "Mod+Shift+I".action.spawn = [ "${colorPicker}/bin/color-picker" ];
      "Mod+O".action.spawn = [ "${booksScript}/bin/open_books" ];

      # Volume
      "Mod+Equal".action.spawn = volumeUp;
      "Mod+Minus".action.spawn = volumeDown;

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = volumeUp;
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = volumeDown;
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgs.wireplumber}/bin/wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgs.wireplumber}/bin/wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
      };

      # Brightness
      "Mod+BracketRight".action.spawn = [
        "${pkgsStable.brightnessctl}/bin/brightnessctl"
        "s"
        "10%+"
      ];
      "Mod+BracketLeft".action.spawn = [
        "${pkgsStable.brightnessctl}/bin/brightnessctl"
        "s"
        "10%-"
      ];

      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgsStable.playerctl}/bin/playerctl"
          "next"
        ];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgsStable.playerctl}/bin/playerctl"
          "previous"
        ];
      };
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgsStable.playerctl}/bin/playerctl"
          "play-pause"
        ];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = [
          "${pkgsStable.playerctl}/bin/playerctl"
          "play-pause"
        ];
      };

      # Multi-monitor
      "Mod+Alt+Left".action.focus-monitor-left = [ ];
      "Mod+Alt+Right".action.focus-monitor-right = [ ];
      "Mod+Alt+Up".action.focus-monitor-up = [ ];
      "Mod+Alt+Down".action.focus-monitor-down = [ ];
      "Mod+Alt+Shift+Left".action.move-column-to-monitor-left = [ ];
      "Mod+Alt+Shift+Right".action.move-column-to-monitor-right = [ ];
      "Mod+Alt+Shift+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Alt+Shift+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Alt+Shift+Page_Up".action.move-workspace-to-monitor-up = [ ];
      "Mod+Alt+Shift+Page_Down".action.move-workspace-to-monitor-down = [ ];

      "Mod+F1".action.spawn = noctalia "plugin:keybind-cheatsheet toggle";
      "Mod+Shift+P".action.power-off-monitors = [ ];
    }
    // workspaceFocusBinds
    // workspaceMoveBinds;
}
