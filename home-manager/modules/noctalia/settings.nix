# Noctalia Shell settings (theme, dock, wallpaper, OSD, control center)

{
  constants,
  lib,
  pkgs,
  ...
}:

let
  mkControlCenterCard = id: enabled: {
    inherit id enabled;
  };
  mkSessionPowerOption = action: keybind: {
    inherit action keybind;
    command = "";
    countdownEnabled = true;
    enabled = true;
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
      hideWeatherTimezone = true;
      hideWeatherCityName = true;
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
      dimmerOpacity = 0.72;
      scaleRatio = 0.95;
      animationDisabled = false;
      animationSpeed = 1.2;
      enableLockScreenMediaControls = false;
      enableShadows = false;
      enableBlurBehind = true;
      passwordChars = false;
      radiusRatio = 0;
      iRadiusRatio = 0;
      boxRadiusRatio = 0;
      screenRadiusRatio = 0;
      keybinds.keyEnter = [
        "Return"
        "Enter"
      ];
    };

    ui = {
      scrollbarAlwaysVisible = true;
      translucentWidgets = false;
      panelBackgroundOpacity = 1;
      boxBorderEnabled = true;
      settingsPanelSideBarCardStyle = false;
    };

    bar = {
      barType = "floating";
      density = "default";
      showOutline = false;
      showCapsule = false;
      widgetSpacing = 6;
      contentPadding = 2;
      fontScale = 1;
      enableExclusionZoneInset = true;
      backgroundOpacity = 1;
      floating = true;
      marginVertical = 0;
      marginHorizontal = 6;
      frameThickness = 0;
      frameRadius = 0;
      outerCorners = false;
      showOnWorkspaceSwitch = true;
      mouseWheelAction = "none";
      reverseScroll = false;
      mouseWheelWrap = true;
      middleClickAction = "none";
      middleClickFollowMouse = false;
      middleClickCommand = "";
      rightClickAction = "controlCenter";
      rightClickFollowMouse = true;
      rightClickCommand = "";
    };

    appLauncher = {
      overviewLayer = true;
      enableClipboardHistory = true;
      enableClipboardSmartIcons = true;
      enableClipboardChips = true;
      viewMode = "list";
      showCategories = true;
      showIconBackground = false;
      terminalCommand = "${constants.terminal} -e";
    };

    wallpaper = {
      enabled = false;
      fillMode = "crop";
      transitionDuration = 1500;
      transitionType = [ "fade" ];
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
      spectrumFrameRate = 30;
      visualizerType = "mirrored";
      volumeFeedbackSoundFile = "";
    };

    dock = {
      enabled = false;
      displayMode = "auto_hide";
      position = "bottom";
      showLauncherIcon = false;
      launcherPosition = "end";
      launcherUseDistroLogo = false;
      launcherIcon = "";
      launcherIconColor = "none";
      groupApps = false;
      groupContextMenuMode = "extended";
      groupClickAction = "cycle";
      groupIndicatorStyle = "dots";
      showDockIndicator = false;
      indicatorThickness = 3;
      indicatorColor = "primary";
      indicatorOpacity = 0.6;
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

    network = {
      networkPanelView = "wifi";
      bluetoothAutoConnect = true;
    };

    brightness = {
      backlightDeviceMappings = [ ];
    };

    noctaliaPerformance = {
      disableWallpaper = true;
      disableDesktopWidgets = true;
    };

    sessionMenu.powerOptions = [
      (mkSessionPowerOption "lock" "1")
      (mkSessionPowerOption "suspend" "2")
      (mkSessionPowerOption "hibernate" "3")
      (mkSessionPowerOption "reboot" "4")
      (mkSessionPowerOption "logout" "5")
      (mkSessionPowerOption "shutdown" "6")
      (mkSessionPowerOption "rebootToUefi" "")
    ];

    hooks = {
      enabled = true;
      screenLock = "playerctl pause";
      screenUnlock = "playerctl play";
      colorGeneration = "";
    };

    plugins = {
      notifyUpdates = true;
    };

    idle = {
      enabled = false;
      screenOffTimeout = 600;
      lockTimeout = 660;
      suspendTimeout = 1800;
      fadeDuration = 5;
      screenOffCommand = "";
      lockCommand = "";
      suspendCommand = "";
      resumeScreenOffCommand = "";
      resumeLockCommand = "";
      resumeSuspendCommand = "";
      customCommands = "[]";
    };

    desktopWidgets = {
      enabled = true;
      overviewEnabled = true;
      gridSnap = true;
      gridSnapScale = false;
    };

    controlCenter = {
      cards = [
        (mkControlCenterCard "profile-card" true)
        (mkControlCenterCard "shortcuts-card" true)
        (mkControlCenterCard "audio-card" true)
        (mkControlCenterCard "brightness-card" true)
        (mkControlCenterCard "weather-card" true)
        (mkControlCenterCard "media-sysmon-card" true)
      ];
    };
  };

  home = {
    # Keep the generated settings free of location data in the Nix store.
    # If present, the runtime secret is injected into the mutable settings.json.
    activation = {
      backupNoctaliaPluginSettings = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
        PLUGIN_STATE_DIR="$HOME/.local/state/noctalia/plugin-settings"
        mkdir -p "$PLUGIN_STATE_DIR"

        for PLUGIN_ID in mawaqit model-usage; do
          PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"
          SETTINGS_PATH="$PLUGIN_DIR/settings.json"
          if [ -f "$SETTINGS_PATH" ]; then
            cp "$SETTINGS_PATH" "$PLUGIN_STATE_DIR/$PLUGIN_ID.json"
          fi
        done

        for PLUGIN_ID in keybind-cheatsheet mawaqit model-usage music-search; do
          PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"
          if [ -e "$PLUGIN_DIR" ] && [ ! -L "$PLUGIN_DIR" ]; then
            chmod -R u+w "$PLUGIN_DIR" 2>/dev/null || true
            rm -rf "$PLUGIN_DIR"
          fi
          if [ -e "$PLUGIN_DIR.backup" ] && [ ! -L "$PLUGIN_DIR.backup" ]; then
            chmod -R u+w "$PLUGIN_DIR.backup" 2>/dev/null || true
            rm -rf "$PLUGIN_DIR.backup"
          fi
        done
      '';

      materializeNoctaliaPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        PLUGIN_STATE_DIR="$HOME/.local/state/noctalia/plugin-settings"

        for PLUGIN_ID in keybind-cheatsheet mawaqit model-usage music-search; do
          PLUGIN_DIR="$HOME/.config/noctalia/plugins/$PLUGIN_ID"

          if [ ! -e "$PLUGIN_DIR" ]; then
            continue
          fi

          TMPDIR=$(mktemp -d)
          cp -aL "$PLUGIN_DIR/." "$TMPDIR/"
          rm -rf "$PLUGIN_DIR"
          mkdir -p "$PLUGIN_DIR"
          cp -a "$TMPDIR/." "$PLUGIN_DIR/"
          chmod -R u+w "$PLUGIN_DIR"
          chmod -R u+w "$TMPDIR"
          rm -rf "$TMPDIR"

          if [ -f "$PLUGIN_STATE_DIR/$PLUGIN_ID.json" ]; then
            cp "$PLUGIN_STATE_DIR/$PLUGIN_ID.json" "$PLUGIN_DIR/settings.json"
          fi
        done
      '';

      patchNoctaliaLocation = lib.hm.dag.entryAfter [ "materializeNoctaliaPlugins" ] ''
              SETTINGS_FILE="$HOME/.config/noctalia/settings.json"
              LOCATION_SECRET="/run/secrets/noctalia_location"
              MAWAQIT_SETTINGS="$HOME/.config/noctalia/plugins/mawaqit/settings.json"
              MODEL_USAGE_SETTINGS="$HOME/.config/noctalia/plugins/model-usage/settings.json"

              if [ -e "$SETTINGS_FILE" ]; then
                if [ -f "$LOCATION_SECRET" ]; then
                  LOCATION=$(cat "$LOCATION_SECRET")
                  CITY=$(printf '%s' "$LOCATION" | sed -E 's/^[[:space:]]*([^,]+).*$/\1/' | sed -E 's/[[:space:]]+$//')
                  COUNTRY=$(printf '%s' "$LOCATION" | sed -nE 's/^[^,]+,[[:space:]]*(.+)$/\1/p' | sed -E 's/[[:space:]]+$//')
                else
                  LOCATION=""
                  CITY=""
                  COUNTRY=""
                fi

                TMPFILE=$(mktemp)
                ${pkgs.jq}/bin/jq \
                  --arg loc "$LOCATION" \
                  '
                    .location.name = $loc
                  ' \
                  "$SETTINGS_FILE" > "$TMPFILE"

                # Replace the Nix store symlink with a mutable real file, or refresh an existing patched file.
                rm -f "$SETTINGS_FILE"
                mv "$TMPFILE" "$SETTINGS_FILE"

                if [ "$CITY" != "" ] && [ "$COUNTRY" != "" ]; then
                  mkdir -p "$(dirname "$MAWAQIT_SETTINGS")"
                  if [ -f "$MAWAQIT_SETTINGS" ]; then
                    TMPFILE=$(mktemp)
                    ${pkgs.jq}/bin/jq --arg city "$CITY" --arg country "$COUNTRY" '
                      .city = $city
                      | .country = $country
                    ' "$MAWAQIT_SETTINGS" > "$TMPFILE"
                    mv "$TMPFILE" "$MAWAQIT_SETTINGS"
                  else
                    printf '{\n  "city": "%s",\n  "country": "%s"\n}\n' "$CITY" "$COUNTRY" > "$MAWAQIT_SETTINGS"
                  fi
                fi

                mkdir -p "$(dirname "$MODEL_USAGE_SETTINGS")"
                if [ -f "$MODEL_USAGE_SETTINGS" ]; then
                  TMPFILE=$(mktemp)
                  ${pkgs.jq}/bin/jq '
                    (.providers //= {})
                    | (.providers.codex //= {})
                    | (.providers.zai //= {})
                    | (.providers.codex.enabled //= true)
                    | (.providers.zai.enabled //= true)
                  ' "$MODEL_USAGE_SETTINGS" > "$TMPFILE"
                  mv "$TMPFILE" "$MODEL_USAGE_SETTINGS"
                else
                  cat > "$MODEL_USAGE_SETTINGS" <<'EOF'
        {
          "providers": {
            "codex": {
              "enabled": true
            },
            "zai": {
              "enabled": true
            }
          }
        }
        EOF
                fi
              fi
      '';
    };
  };
}
