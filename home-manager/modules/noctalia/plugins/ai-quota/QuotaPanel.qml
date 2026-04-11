import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  property bool allowAttach: true
  property int contentPreferredWidth: 432
  property int contentPreferredHeight: 640

  property bool loading: false
  property string lastError: ""
  property var quotaData: ({
    "summary": "Z-- C-- O--",
    "updatedLabel": "Waiting for data",
    "updatedEpoch": 0,
    "icon": "activity",
    "accent": "#83a598",
    "providers": []
  })
  readonly property var providers: quotaData && quotaData.providers ? quotaData.providers : []
  property int selectedIndex: 0
  readonly property var selectedProvider: providers.length > 0 ? providers[Math.min(selectedIndex, providers.length - 1)] : null

  readonly property color bg0: "#1d2021"
  readonly property color bg1: "#282828"
  readonly property color bg2: "#32302f"
  readonly property color bg3: "#3c3836"
  readonly property color fg0: "#fbf1c7"
  readonly property color fg1: "#ebdbb2"
  readonly property color fg2: "#d5c4a1"
  readonly property color fg3: "#a89984"
  readonly property color border: "#504945"
  readonly property color blue: "#83a598"
  readonly property color aqua: "#8ec07c"
  readonly property color yellow: "#fabd2f"
  readonly property color red: "#fb4934"

  function pctNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.max(0, Math.min(100, parsed)) : -1;
  }

  function progressWidth(value, total) {
    const pct = pctNumber(value);
    if (pct < 0 || total <= 0)
      return 0;
    return Math.round((pct / 100) * total);
  }

  function openExternal(url) {
    if (url)
      Quickshell.execDetached(["xdg-open", url]);
  }

  function refresh() {
    if (!fetchProcess.running) {
      loading = true;
      fetchProcess.running = true;
    }
  }

  function dashboardUrl(providerId) {
    switch (providerId) {
    case "codex":
      return "https://platform.openai.com/usage";
    case "claude":
      return "https://console.anthropic.com/settings/billing";
    case "zai":
      return "https://chat.z.ai/";
    default:
      return "";
    }
  }

  Timer {
    interval: 300000
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
      root.loading = false;

      if (exitCode !== 0) {
        root.lastError = stderr.text.trim() || "Quota refresh failed";
        return;
      }

      try {
        const parsed = JSON.parse(stdout.text.trim());
        parsed.providers = parsed.providers || [];
        root.quotaData = parsed;
        if (root.selectedIndex >= parsed.providers.length)
          root.selectedIndex = 0;
        root.lastError = "";
      } catch (error) {
        root.lastError = "Quota payload parse failed";
      }
    }
  }

  Component.onCompleted: root.refresh()

  Rectangle {
    anchors.fill: parent
    radius: 22
    color: root.bg0
    border.width: 1
    border.color: root.border

    Flickable {
      anchors.fill: parent
      anchors.margins: 14
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: contentColumn

        width: parent.width
        spacing: 14

        Rectangle {
          Layout.fillWidth: true
          radius: 18
          color: root.bg1
          border.width: 1
          border.color: root.border
          implicitHeight: headerColumn.implicitHeight + 26

          ColumnLayout {
            id: headerColumn

            anchors.fill: parent
            anchors.margins: 13
            spacing: 12

            RowLayout {
              Layout.fillWidth: true

              ColumnLayout {
                spacing: 3

                Text {
                  text: "AI Quota"
                  color: root.fg0
                  font.pixelSize: 22
                  font.weight: Font.DemiBold
                }

                Text {
                  text: quotaData.summary
                  color: root.fg3
                  font.pixelSize: 12
                }
              }

              Item { Layout.fillWidth: true }

              Rectangle {
                radius: 10
                color: Qt.alpha(root.quotaData.accent, 0.18)
                border.width: 1
                border.color: Qt.alpha(root.quotaData.accent, 0.48)
                implicitWidth: updatedText.implicitWidth + 18
                implicitHeight: updatedText.implicitHeight + 10

                Text {
                  id: updatedText
                  anchors.centerIn: parent
                  text: quotaData.updatedLabel
                  color: root.fg1
                  font.pixelSize: 11
                  font.weight: Font.Medium
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 44
              radius: 13
              color: root.bg0
              border.width: 1
              border.color: root.border

              RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 6

                Repeater {
                  model: root.providers

                  delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 10
                    color: index === root.selectedIndex ? modelData.accent : "transparent"
                    border.width: index === root.selectedIndex ? 0 : 1
                    border.color: root.border

                    Text {
                      anchors.centerIn: parent
                      text: modelData.name
                      color: index === root.selectedIndex ? root.bg0 : root.fg2
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.selectedIndex = index
                    }
                  }
                }
              }
            }

            Text {
              visible: root.loading || root.lastError !== ""
              text: root.loading ? "Refreshing live quota data..." : root.lastError
              color: root.loading ? root.blue : root.red
              font.pixelSize: 11
              wrapMode: Text.Wrap
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          radius: 18
          color: root.bg1
          border.width: 1
          border.color: root.border
          implicitHeight: providerHeaderColumn.implicitHeight + 28

          ColumnLayout {
            id: providerHeaderColumn

            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
              Layout.fillWidth: true

              ColumnLayout {
                spacing: 3

                Text {
                  text: root.selectedProvider ? root.selectedProvider.name : "No provider"
                  color: root.fg0
                  font.pixelSize: 28
                  font.weight: Font.DemiBold
                }

                Text {
                  text: root.selectedProvider ? root.selectedProvider.subtitle : "Waiting for provider data"
                  color: root.fg3
                  font.pixelSize: 13
                }
              }

              Item { Layout.fillWidth: true }

              ColumnLayout {
                spacing: 5

                Text {
                  text: root.selectedProvider ? root.selectedProvider.headline : "No data"
                  color: root.selectedProvider ? root.selectedProvider.accent : root.fg3
                  font.pixelSize: 22
                  font.weight: Font.DemiBold
                  horizontalAlignment: Text.AlignRight
                }

                Text {
                  text: quotaData.updatedLabel
                  color: root.fg3
                  font.pixelSize: 11
                  horizontalAlignment: Text.AlignRight
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              spacing: 8

              Repeater {
                model: root.selectedProvider && root.selectedProvider.badges ? root.selectedProvider.badges : []

                delegate: Rectangle {
                  required property var modelData

                  radius: 9
                  color: Qt.alpha(root.selectedProvider ? root.selectedProvider.accent : root.blue, 0.14)
                  border.width: 1
                  border.color: Qt.alpha(root.selectedProvider ? root.selectedProvider.accent : root.blue, 0.34)
                  implicitWidth: badgeText.implicitWidth + 16
                  implicitHeight: badgeText.implicitHeight + 8

                  Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: modelData
                    color: root.fg1
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                  }
                }
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Rectangle {
            Layout.fillWidth: true
            radius: 18
            color: root.bg1
            border.width: 1
            border.color: root.border
            implicitHeight: primaryCard.implicitHeight + 26

            ColumnLayout {
              id: primaryCard

              anchors.fill: parent
              anchors.margins: 13
              spacing: 10

              Text {
                text: root.selectedProvider && root.selectedProvider.primary ? root.selectedProvider.primary.label : "Primary"
                color: root.fg2
                font.pixelSize: 16
                font.weight: Font.DemiBold
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 10
                radius: 5
                color: root.bg0

                Rectangle {
                  width: root.progressWidth(root.selectedProvider && root.selectedProvider.primary ? root.selectedProvider.primary.pct : "", parent.width)
                  height: parent.height
                  radius: 5
                  color: root.selectedProvider ? root.selectedProvider.accent : root.blue
                }
              }

              Text {
                text: root.selectedProvider && root.selectedProvider.primary ? root.selectedProvider.primary.value : "No data"
                color: root.fg0
                font.pixelSize: 14
                font.weight: Font.Medium
              }

              Text {
                text: root.selectedProvider && root.selectedProvider.primary ? root.selectedProvider.primary.meta : ""
                color: root.fg3
                font.pixelSize: 12
                wrapMode: Text.Wrap
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            radius: 18
            color: root.bg1
            border.width: 1
            border.color: root.border
            implicitHeight: secondaryCard.implicitHeight + 26

            ColumnLayout {
              id: secondaryCard

              anchors.fill: parent
              anchors.margins: 13
              spacing: 10

              Text {
                text: root.selectedProvider && root.selectedProvider.secondary ? root.selectedProvider.secondary.label : "Secondary"
                color: root.fg2
                font.pixelSize: 16
                font.weight: Font.DemiBold
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 10
                radius: 5
                color: root.bg0

                Rectangle {
                  visible: root.selectedProvider && root.selectedProvider.secondary && root.pctNumber(root.selectedProvider.secondary.pct) >= 0
                  width: root.progressWidth(root.selectedProvider && root.selectedProvider.secondary ? root.selectedProvider.secondary.pct : "", parent.width)
                  height: parent.height
                  radius: 5
                  color: root.selectedProvider ? Qt.lighter(root.selectedProvider.accent, 1.1) : root.aqua
                }
              }

              Text {
                text: root.selectedProvider && root.selectedProvider.secondary ? root.selectedProvider.secondary.value : "No data"
                color: root.fg0
                font.pixelSize: 14
                font.weight: Font.Medium
              }

              Text {
                text: root.selectedProvider && root.selectedProvider.secondary ? root.selectedProvider.secondary.meta : ""
                color: root.fg3
                font.pixelSize: 12
                wrapMode: Text.Wrap
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          radius: 18
          color: root.bg1
          border.width: 1
          border.color: root.border
          implicitHeight: detailsColumn.implicitHeight + 26

          ColumnLayout {
            id: detailsColumn

            anchors.fill: parent
            anchors.margins: 13
            spacing: 12

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: root.selectedProvider && root.selectedProvider.available ? "Details" : "Status"
                color: root.fg2
                font.pixelSize: 16
                font.weight: Font.DemiBold
              }

              Item { Layout.fillWidth: true }

              Text {
                visible: root.selectedProvider
                text: root.selectedProvider ? root.selectedProvider.short + " / " + root.selectedProvider.name : ""
                color: root.fg3
                font.pixelSize: 11
              }
            }

            Rectangle {
              visible: root.selectedProvider && !root.selectedProvider.available
              Layout.fillWidth: true
              radius: 14
              color: "#3c2d28"
              border.width: 1
              border.color: "#9d0006"
              implicitHeight: unavailableColumn.implicitHeight + 22

              ColumnLayout {
                id: unavailableColumn

                anchors.fill: parent
                anchors.margins: 11
                spacing: 6

                Text {
                  text: root.selectedProvider ? root.selectedProvider.error : "Provider unavailable"
                  color: "#fb4934"
                  font.pixelSize: 13
                  font.weight: Font.DemiBold
                  wrapMode: Text.Wrap
                }

                Text {
                  text: "The panel is live, but this provider could not be queried in the current session."
                  color: root.fg2
                  font.pixelSize: 12
                  wrapMode: Text.Wrap
                }
              }
            }

            GridLayout {
              visible: root.selectedProvider && root.selectedProvider.available
              Layout.fillWidth: true
              columns: 2
              columnSpacing: 12
              rowSpacing: 10

              Repeater {
                model: root.selectedProvider && root.selectedProvider.details ? root.selectedProvider.details : []

                delegate: Rectangle {
                  required property var modelData

                  Layout.fillWidth: true
                  radius: 14
                  color: root.bg2
                  border.width: 1
                  border.color: "#4b443f"
                  implicitHeight: detailColumn.implicitHeight + 18

                  ColumnLayout {
                    id: detailColumn

                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    Text {
                      text: modelData.label
                      color: root.fg3
                      font.pixelSize: 11
                    }

                    Text {
                      text: modelData.value
                      color: root.fg0
                      font.pixelSize: 13
                      font.weight: Font.Medium
                      wrapMode: Text.Wrap
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 36
                radius: 11
                color: root.blue

                Text {
                  anchors.centerIn: parent
                  text: "Refresh"
                  color: root.bg0
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.refresh()
                }
              }

              Rectangle {
                Layout.preferredWidth: 148
                Layout.preferredHeight: 36
                radius: 11
                color: root.bg2
                border.width: 1
                border.color: root.border

                Text {
                  anchors.centerIn: parent
                  text: "Usage Dashboard"
                  color: root.fg1
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.openExternal(root.dashboardUrl(root.selectedProvider ? root.selectedProvider.id : ""))
                }
              }

              Item { Layout.fillWidth: true }
            }
          }
        }
      }
    }
  }
}
