# Noctalia Shell desktop environment.

{
  constants,
  inputs,
  ...
}:

{
  imports = [ inputs.noctalia.homeModules.default ];

  # Required for system tray icons (SNI protocol).
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell = {
    enable = true;

    settings = {
      colorSchemes = {
        predefinedScheme = "Gruvbox";
        darkMode = true;
      };

      bar = {
        position = "top";
        floating = false;
        widgets = {
          left = [
            {
              id = "Launcher";
              icon = "layout-grid";
              usePrimaryColor = true;
            }
            {
              id = "Clock";
              formatHorizontal = "hh:mm a ddd, MMM dd";
            }
            {
              id = "SystemMonitor";
              compactMode = false;
              showGpuTemp = true;
              showNetworkStats = false;
              showDiskUsage = true;
            }
            {
              id = "ActiveWindow";
              showIcon = true;
              maxWidth = 200;
              scrollingMode = "hover";
            }
          ];
          center = [
            {
              id = "Workspace";
              showApplications = true;
              labelMode = "name";
              hideUnoccupied = false;
              showLabelsOnlyWhenOccupied = false;
              enableScrollWheel = true;
              colorizeIcons = false;
            }
            {
              id = "Taskbar";
              onlySameOutput = true;
              showTitle = false;
              colorizeIcons = false;
              iconScale = 0.8;
              smartWidth = true;
              maxTaskbarWidth = 40;
            }
          ];
          right = [
            {
              id = "Tray";
              drawerEnabled = false;
              hidePassive = false;
            }
            {
              id = "CustomButton";
              icon = "shield-lock";
              showIcon = true;
              hideMode = "alwaysExpanded";
              textCommand = "mullvad status | grep -oP '(Connected|Disconnected|Connecting)'";
              textIntervalMs = 5000;
              textCollapse = "Disconnected";
              leftClickExec = "mullvad connect";
              rightClickExec = "mullvad disconnect";
              maxTextLength = {
                horizontal = 12;
                vertical = 6;
              };
            }
            { id = "NotificationHistory"; }
            {
              id = "Microphone";
              displayMode = "onhover";
            }
            { id = "Volume"; }
            {
              id = "ControlCenter";
              icon = "settings";
            }
          ];
        };
      };

      # Timezone offset avoids leaking location to weather APIs.
      location = {
        name = "UTC+3";
        use12hourFormat = true;
      };

      nightLight = {
        enabled = true;
        dayTemp = 6500;
        nightTemp = 3500;
      };

      notifications = {
        location = "top-right";
      };

      general = {
        compactLockScreen = false;
        showChangelogOnStartup = false;
      };

      appLauncher = {
        enableClipboardHistory = true;
        viewMode = "grid";
        showCategories = true;
        showIconBackground = false;
        terminalCommand = "ghostty -e";
      };

      wallpaper = {
        enabled = true;
        fillMode = "crop";
        transitionDuration = 1500;
        transitionType = "fade";
        automationEnabled = true;
        wallpaperChangeMode = "random";
        randomIntervalSec = 600;
      };

      dock = {
        enabled = true;
        displayMode = "auto_hide";
        position = "bottom";
        pinnedApps = [
          "brave-browser"
          constants.terminalAppId
          constants.editor
          "vesktop"
          "org.telegram.desktop"
        ];
      };

      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
      };

      hooks = {
        enabled = true;
        screenLock = "playerctl pause";
        screenUnlock = "playerctl play";
      };

      desktopWidgets = {
        enabled = true;
        gridSnap = true;
      };

      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = true;
            id = "brightness-card";
          }
          {
            enabled = false;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };
    };
  };
}
