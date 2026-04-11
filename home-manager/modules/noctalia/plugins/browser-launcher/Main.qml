import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property var pluginApi: null
    property string pendingUrl: ""
    property int launcherRequestSerial: 0

    Process {
        id: launchProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function queueUrl(url) {
        root.pendingUrl = (url || "").trim();
        root.launcherRequestSerial = root.launcherRequestSerial + 1;
    }

    function consumePendingUrl() {
        const value = root.pendingUrl;
        root.pendingUrl = "";
        return value;
    }

    function openBrowserLauncher(url) {
        if (!pluginApi)
            return;

        queueUrl(url);
        pluginApi.withCurrentScreen(function(screen) {
            pluginApi.openLauncher(screen);
        });
    }

    function launchBrowser(command, url) {
        const finalUrl = (url || "").trim();
        const args = [command];
        if (finalUrl !== "")
            args.push(finalUrl);

        launchProcess.exec({
            command: args
        });
    }

    IpcHandler {
        target: "plugin:browser-launcher"

        function toggle() {
            if (!root.pluginApi)
                return;

            root.pluginApi.withCurrentScreen(function(screen) {
                root.pluginApi.toggleLauncher(screen);
            });
        }

        function open() {
            root.openBrowserLauncher("");
        }

        function openUrl(url: string) {
            root.openBrowserLauncher(url);
        }
    }
}
