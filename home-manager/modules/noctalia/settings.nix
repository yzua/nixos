# Noctalia Shell settings (theme, dock, wallpaper, OSD, control center)

{ constants, ... }:

let
  mkControlCenterCard = id: enabled: {
    inherit id enabled;
  };
in

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
      backgroundOpacity = 0.96;
      respectExpireTimeout = true;
      lowUrgencyDuration = 3;
      normalUrgencyDuration = 6;
      criticalUrgencyDuration = 10;
    };

    general = {
      compactLockScreen = false;
      showChangelogOnStartup = false;
      dimmerOpacity = 0.57;
      enableShadows = false;
      radiusRatio = 0;
      iRadiusRatio = 0.35;
      boxRadiusRatio = 0;
      screenRadiusRatio = 0;
    };

    ui = {
      panelBackgroundOpacity = 1;
    };

    bar = {
      density = "compact";
      showOutline = false;
      showCapsule = false;
      backgroundOpacity = 1;
      marginVertical = 0;
      marginHorizontal = 0;
      frameThickness = 0;
      frameRadius = 0;
      outerCorners = false;
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
        (mkControlCenterCard "profile-card" true)
        (mkControlCenterCard "shortcuts-card" true)
        (mkControlCenterCard "audio-card" true)
        (mkControlCenterCard "brightness-card" true)
        (mkControlCenterCard "weather-card" false)
        (mkControlCenterCard "media-sysmon-card" true)
      ];
    };
  };
}
