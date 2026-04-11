import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
  id: root

  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: 0
  property int sectionWidgetsCount: 1

  property string summary: "AI"
  property string accent: "#83a598"
  property string updatedLabel: ""

  implicitWidth: row.implicitWidth + 20
  implicitHeight: 28
  radius: 9
  color: mouse.containsMouse ? "#3c3836" : "#282828"
  border.width: 1
  border.color: mouse.containsMouse ? Qt.lighter(root.accent, 1.1) : "#504945"

  function refresh() {
    if (!fetchProcess.running)
      fetchProcess.running = true;
  }

  Timer {
    interval: 120000
    repeat: true
    running: true
    onTriggered: root.refresh()
  }

  Process {
    id: fetchProcess

    command: ["sh", "-lc", "@API_QUOTA_SCRIPT@ data"]
    running: false
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0)
        return;

      try {
        const parsed = JSON.parse(stdout.text.trim());
        root.summary = parsed.summary || "AI";
        root.accent = parsed.accent || "#83a598";
        root.updatedLabel = parsed.updatedLabel || "";
      } catch (error) {
      }
    }
  }

  Component.onCompleted: root.refresh()

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 7

    Rectangle {
      implicitWidth: 10
      implicitHeight: 10
      radius: 5
      color: root.accent
      border.width: 1
      border.color: Qt.darker(root.accent, 1.2)
    }

    Text {
      text: root.summary
      color: "#ebdbb2"
      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) {
        root.refresh();
        return;
      }

      if (pluginApi)
        pluginApi.openPanel(root.screen, root);
    }
  }
}
