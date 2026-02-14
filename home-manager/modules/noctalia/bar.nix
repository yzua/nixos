{ pkgs, apiQuotaScript, ... }:
{
  programs.noctalia-shell.settings.bar = {
    position = "top";
    floating = false;
    widgets = {
      left = [
        {
          id = "Clock";
          formatHorizontal = "hh:mm a ddd, MMM dd";
        }
        {
          id = "SystemMonitor";
          compactMode = false;
          showGpuTemp = true;
          showNetworkStats = true;
          showDiskUsage = true;
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
          id = "MediaMini";
          hideMode = "hidden";
          maxWidth = 145;
          showArtistFirst = true;
          showProgressRing = true;
          scrollingMode = "hover";
          panelShowAlbumArt = true;
          panelShowVisualizer = true;
          visualizerType = "linear";
        }
        {
          id = "Network";
          displayMode = "onhover";
        }
        {
          id = "Tray";
          colorizeIcons = true;
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
        {
          id = "CustomButton";
          icon = "activity";
          showIcon = true;
          hideMode = "alwaysExpanded";
          parseJson = true;
          textCommand = "${apiQuotaScript}";
          textIntervalMs = 120000;
          leftClickUpdateText = true;
        }
        { id = "NotificationHistory"; }
        {
          id = "Microphone";
          displayMode = "onhover";
        }
        {
          id = "Volume";
          displayMode = "onhover";
        }
        {
          id = "ControlCenter";
          icon = "settings";
        }
      ];
    };
  };
}
