{ constants, ... }:
{
  programs.noctalia-shell.settings = {
    colorSchemes = {
      predefinedScheme = "Gruvbox";
      darkMode = true;
    };

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
      location = "top_right";
    };

    general = {
      compactLockScreen = false;
      showChangelogOnStartup = false;
      dimmerOpacity = 0.57;
    };

    ui = {
      panelBackgroundOpacity = 1;
    };

    appLauncher = {
      enableClipboardHistory = true;
      viewMode = "list";
      showCategories = true;
      showIconBackground = false;
      terminalCommand = "${constants.terminal} -e";
    };

    wallpaper = {
      enabled = false;
      fillMode = "crop";
      transitionDuration = 1500;
      transitionType = "fade";
      automationEnabled = true;
      wallpaperChangeMode = "random";
      randomIntervalSec = 600;
    };

    systemMonitor = {
      enableDgpuMonitoring = true;
      useCustomColors = false;
      warningColor = constants.color.blue; # #83a598
      criticalColor = constants.color.red; # #fb4934
    };

    audio = {
      visualizerType = "mirrored";
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
}
