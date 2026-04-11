import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  property bool loading: false
  property string lastError: ""
  property var quotaData: ({
    "summary": "Z-- C-- O--",
    "updatedLabel": "Waiting for data",
    "updatedEpoch": 0,
    "icon": "activity",
    "providers": []
  })

  visible: false
  width: 0
  height: 0

  function refresh() {
    if (fetchProcess.running)
      return;
    loading = true;
    fetchProcess.running = true;
  }

  function providerAt(index) {
    if (!quotaData || !quotaData.providers || index < 0 || index >= quotaData.providers.length)
      return null;
    return quotaData.providers[index];
  }

  function providerById(id) {
    if (!quotaData || !quotaData.providers)
      return null;
    for (var i = 0; i < quotaData.providers.length; i++) {
      if (quotaData.providers[i].id === id)
        return quotaData.providers[i];
    }
    return null;
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
        var parsed = JSON.parse(stdout.text.trim());
        parsed.providers = parsed.providers || [];
        root.quotaData = parsed;
        root.lastError = "";
      } catch (error) {
        root.lastError = "Quota payload parse failed";
      }
    }
  }

  Component.onCompleted: root.refresh()
}
