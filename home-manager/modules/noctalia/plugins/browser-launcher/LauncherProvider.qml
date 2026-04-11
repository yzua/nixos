import QtQuick
import Quickshell
import qs.Commons
import "BrowserEntries.js" as BrowserEntries

Item {
    id: root

    property var pluginApi: null
    property var launcher: null
    property string name: "Browser"
    property bool handleSearch: false
    property string supportedLayouts: "list"

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property string homePath: Quickshell.env("HOME") ?? "/home"
    readonly property string commandName: ">" + (pluginApi?.manifest?.metadata?.commandPrefix || "browser")

    Connections {
        target: root.mainInstance

        function onLauncherRequestSerialChanged() {
            root.applyPendingRequest();
        }
    }

    function onOpened() {
        root.applyPendingRequest();
    }

    function applyPendingRequest() {
        if (!launcher || !mainInstance)
            return;

        const pendingUrl = mainInstance.consumePendingUrl();
        if (pendingUrl === "")
            return;

        Qt.callLater(function() {
            launcher.setSearchText(commandName + " " + pendingUrl);
        });
    }

    function handleCommand(searchText) {
        return searchText.startsWith(commandName);
    }

    function commands() {
        return [
            {
                "name": commandName,
                "description": "Open a browser profile chooser",
                "icon": "world",
                "isTablerIcon": true,
                "onActivate": function() {
                    launcher.setSearchText(commandName + " ");
                }
            }
        ];
    }

    function looksLikeUrl(value) {
        const trimmed = (value || "").trim();
        return /^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) || /^www\./i.test(trimmed);
    }

    function extractQuery(searchText) {
        return searchText.slice(commandName.length).trim();
    }

    function isYouTubeUrl(value) {
        const trimmed = (value || "").trim().toLowerCase();
        return trimmed.indexOf("youtube.com/") >= 0
            || trimmed.indexOf("youtu.be/") >= 0
            || trimmed.indexOf("music.youtube.com/") >= 0;
    }

    function launchEntry(entry, query) {
        const url = looksLikeUrl(query) ? query : "";
        mainInstance?.launchBrowser(entry.launcher, url);
        launcher?.close();
    }

    function filterEntries(query) {
        const allEntries = BrowserEntries.entries(homePath);
        const normalized = (query || "").toLowerCase();
        if (normalized === "" || looksLikeUrl(query)) {
            const results = allEntries.slice();
            if (isYouTubeUrl(query)) {
                results.push({
                    id: "youtube-mpv",
                    name: "MPV (YouTube)",
                    description: "Open YouTube in mpv",
                    launcher: homePath + "/.local/bin/youtube-mpv",
                    icon: "player-play"
                });
            }
            return results;
        }

        return allEntries.filter(function(entry) {
            return entry.name.toLowerCase().indexOf(normalized) >= 0
                || entry.description.toLowerCase().indexOf(normalized) >= 0
                || entry.id.toLowerCase().indexOf(normalized) >= 0;
        });
    }

    function getResults(searchText) {
        if (!searchText.startsWith(commandName))
            return [];

        const query = extractQuery(searchText);
        const entries = filterEntries(query);

        return entries.map(function(entry) {
            return {
                "name": entry.name,
                "description": query !== "" && looksLikeUrl(query) ? query : entry.description,
                "icon": entry.icon,
                "isTablerIcon": true,
                "provider": root,
                "onActivate": function() {
                    root.launchEntry(entry, query);
                }
            };
        });
    }
}
