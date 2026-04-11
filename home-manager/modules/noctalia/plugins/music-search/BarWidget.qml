import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property string barPosition: Settings.data.bar.position || "top"
  readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
  readonly property bool activePlayback: mainInstance?.isPlaying === true || mainInstance?.playbackStarting === true
  readonly property string trackTitle: (mainInstance?.currentTitle || "").trim()
  readonly property string pillText: activePlayback && trackTitle.length > 0 ? trackTitle : ""
  readonly property bool showHoverTrackTitle: pluginApi?.pluginSettings?.showBarHoverTrackTitle
      ?? pluginApi?.manifest?.metadata?.defaultSettings?.showBarHoverTrackTitle
      ?? true
  readonly property string tooltipText: activePlayback
      ? pluginApi?.tr("bar_widget.tooltipPlaying", {"title": trackTitle})
      : pluginApi?.tr("bar_widget.tooltipIdle")

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill

    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    icon: activePlayback ? (mainInstance?.isPaused === true ? "player-pause-filled" : "disc") : "music"
    text: root.showHoverTrackTitle ? root.pillText : ""
    autoHide: false
    rotateText: root.isVerticalBar && root.showHoverTrackTitle && root.pillText.length > 0
    tooltipText: root.tooltipText

    onClicked: {
      pluginApi?.togglePanel(root.screen, pill);
    }

    onRightClicked: {
      PanelService.showContextMenu(contextMenu, pill, root.screen);
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("bar_widget.settings"),
        "action": "widget-settings",
        "icon": "settings",
        "enabled": true
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(root.screen);

      if (action === "widget-settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }
}
