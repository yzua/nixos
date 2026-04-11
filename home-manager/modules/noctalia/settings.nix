# Noctalia Shell settings (theme, dock, wallpaper, OSD, control center)

{
  config,
  constants,
  lib,
  pkgs,
  ...
}:

let
  mkControlCenterCard = id: enabled: {
    inherit id enabled;
  };
in

{
  programs.noctalia-shell.settings = {
    colorSchemes = {
      predefinedScheme = "GruvboxAlt";
      darkMode = true;
    };

    location = {
      name = "";
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

  home.activation.patchNoctaliaLocation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="$HOME/.config/noctalia/settings.json"
    LOCATION_SECRET="/run/secrets/noctalia_location"
    if [ -f "$LOCATION_SECRET" ] && [ -L "$SETTINGS_FILE" ]; then
      LOCATION=$(cat "$LOCATION_SECRET")
      TMPFILE=$(mktemp)
      ${pkgs.jq}/bin/jq --arg loc "$LOCATION" '.location.name = $loc' "$SETTINGS_FILE" > "$TMPFILE"
      # Replace the Nix store symlink with a mutable real file
      rm -f "$SETTINGS_FILE"
      mv "$TMPFILE" "$SETTINGS_FILE"
    fi
  '';
}
