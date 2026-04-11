# Noctalia bar widget layout (left, center, right panels)

_:

let
  mkWidget = id: { inherit id; };
  mkOnHoverWidget = id: {
    inherit id;
    displayMode = "onhover";
  };
in

{
  programs.noctalia-shell.settings.bar = {
    position = "top";
    widgets = {
      left = [
        {
          id = "Clock";
          clockColor = "primary";
          customFont = "Anonymous Pro for Powerline";
          formatHorizontal = "hh:mm a ddd, MMM dd";
          useCustomFont = true;
        }
        {
          id = "SystemMonitor";
          compactMode = true;
          iconColor = "secondary";
          showCpuCores = true;
          showCpuFreq = true;
          showGpuTemp = true;
          showCpuTemp = true;
          showCpuUsage = true;
          showDiskAvailable = true;
          showDiskUsage = true;
          showDiskUsageAsPercent = true;
          showLoadAverage = true;
          showMemoryAsPercent = true;
          showMemoryUsage = true;
          showNetworkStats = false;
          showSwapUsage = true;
          useMonospaceFont = true;
          usePadding = false;
        }
      ];
      center = [
        {
          id = "Workspace";
          showApplications = true;
          labelMode = "none";
          hideUnoccupied = true;
          showLabelsOnlyWhenOccupied = false;
          enableScrollWheel = true;
          colorizeIcons = true;
          emptyColor = "tertiary";
          fontWeight = "bold";
          groupedBorderOpacity = 0.55;
          iconScale = 0.67;
          showApplicationsHover = false;
          unfocusedIconsOpacity = 0.61;
        }
      ];
      right = [
        {
          id = "plugin:model-usage";
        }
        (mkOnHoverWidget "Network")
        {
          id = "Tray";
          colorizeIcons = true;
          drawerEnabled = true;
          hidePassive = true;
        }
        {
          id = "plugin:mawaqit";
        }
        (mkWidget "NotificationHistory")
        (mkOnHoverWidget "Microphone")
        (mkOnHoverWidget "Volume")
        {
          id = "ControlCenter";
          icon = "settings";
        }
      ];
    };
  };
}
