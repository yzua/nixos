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
        (mkOnHoverWidget "Network")
        {
          id = "Tray";
          colorizeIcons = false;
          drawerEnabled = false;
          hidePassive = true;
        }
        {
          id = "plugin:ai-quota";
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
