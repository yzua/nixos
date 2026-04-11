import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property string providerId: "codex"
    property string providerName: "Codex"
    property string providerIcon: "ai"
    property bool enabled: false
    property bool ready: false

    property real rateLimitPercent: -1
    property string rateLimitLabel: "Weekly (7-day)"
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: ""
    property string secondaryRateLimitResetAt: ""

    property int todayPrompts: 0
    property int todaySessions: 0
    property int todayTotalTokens: 0
    property var todayTokensByModel: ({})

    property var recentDays: []
    property int recentPrompts: 0
    property int recentSessions: 0
    property int totalPrompts: 0
    property int totalSessions: 0
    property var modelUsage: ({})
    property string rateLimitDetailText: ""
    property string secondaryRateLimitDetailText: ""

    property string tierLabel: ""
    property string authHelpText: "Run `codex` to authenticate."
    property bool hasLocalStats: true

    property string configModel: ""
    property var providerSettings: ({})

    function resolvePath(p) {
        if (p && p.startsWith("~"))
            return (Quickshell.env("HOME") ?? "/home") + p.substring(1);
        return p;
    }

    function localDateString() {
        const now = new Date();
        const y = now.getFullYear();
        const m = String(now.getMonth() + 1).padStart(2, "0");
        const d = String(now.getDate()).padStart(2, "0");
        return y + "-" + m + "-" + d;
    }

    function dateDaysAgoString(daysAgo) {
        const dt = new Date();
        dt.setHours(0, 0, 0, 0);
        dt.setDate(dt.getDate() - daysAgo);
        const y = dt.getFullYear();
        const m = String(dt.getMonth() + 1).padStart(2, "0");
        const d = String(dt.getDate()).padStart(2, "0");
        return y + "-" + m + "-" + d;
    }

    function labelForWindow(windowMinutes) {
        if (!windowMinutes)
            return "";
        if (windowMinutes === 300)
            return "5h window";
        if (windowMinutes === 10080)
            return "Weekly (7-day)";
        if (windowMinutes % 1440 === 0)
            return Math.round(windowMinutes / 1440) + "d window";
        if (windowMinutes % 60 === 0)
            return Math.round(windowMinutes / 60) + "h window";
        return windowMinutes + "m window";
    }

    FileView {
        id: historyFile
        path: root.resolvePath("~/.codex/history.jsonl")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseHistory(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/codex", "history.jsonl not found");
        }
    }

    FileView {
        id: configFile
        path: root.resolvePath("~/.codex/config.toml")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseConfig(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/codex", "config.toml not found");
        }
    }

    Process {
        id: sessionLister
        command: ["find", root.resolvePath("~/.codex/sessions"), "-type", "f", "-name", "*.jsonl"]
        running: false
        stdout: StdioCollector {
            id: sessionListerOutput
            onStreamFinished: {
                const output = text;
                if (output)
                    root.parseSessionList(output);
            }
        }
    }

    property var sessionPaths: []
    property int sessionPathIndex: -1
    property bool sessionSearchInProgress: false
    property string latestSessionPath: ""
    FileView {
        id: latestSessionFile
        path: root.latestSessionPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseSessionData(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                console.log("model-usage/codex", "Session file not found:", root.latestSessionPath);
                root.loadPreviousSessionFile();
            }
        }
    }

    FileView {
        id: authFile
        path: root.resolvePath("~/.codex/auth.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseAuth(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/codex", "auth.json not found");
        }
    }

    Timer {
        interval: 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.scanSessions()
    }

    onEnabledChanged: {
        if (enabled)
            scanSessions();
    }

    function parseHistory(content) {
        try {
            const lines = content.split("\n");
            const today = root.localDateString();
            const dayCounts = {};
            const todaySessions = {};
            const allSessions = {};
            const recentSessions = {};
            let prompts = 0;
            let recentPrompts = 0;

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    const ts = entry.ts ?? 0;
                    if (!ts)
                        continue;
                    const date = new Date(ts * 1000).toISOString().slice(0, 10);
                    prompts++;
                    if ((new Date(today + "T00:00:00").getTime() - new Date(date + "T00:00:00").getTime()) / 86400000 <= 6)
                        recentPrompts++;
                    dayCounts[date] = (dayCounts[date] ?? 0) + 1;

                    if (entry.session_id) {
                        allSessions[entry.session_id] = true;
                        if (date === today)
                            todaySessions[entry.session_id] = true;
                        if ((new Date(today + "T00:00:00").getTime() - new Date(date + "T00:00:00").getTime()) / 86400000 <= 6)
                            recentSessions[entry.session_id] = true;
                    }
                } catch (e) {
                    continue;
                }
            }

            root.totalPrompts = prompts;
            root.totalSessions = Object.keys(allSessions).length;
            root.todayPrompts = dayCounts[today] ?? 0;
            root.todaySessions = Object.keys(todaySessions).length;
            root.recentPrompts = recentPrompts;
            root.recentSessions = Object.keys(recentSessions).length;

            const recent = [];
            for (let i = 6; i >= 0; i--) {
                const date = root.dateDaysAgoString(i);
                recent.push({
                    date: date,
                    messageCount: dayCounts[date] ?? 0
                });
            }
            root.recentDays = recent;
            root.ready = true;
        } catch (e) {
            console.log("model-usage/codex", "Failed to parse history.jsonl:", e);
        }
    }

    function parseConfig(content) {
        try {
            const match = content.match(/model\s*=\s*"([^"]+)"/);
            if (match)
                root.configModel = match[1];
        } catch (e) {
            console.log("model-usage/codex", "Failed to parse config.toml:", e);
        }
    }

    function parseAuth(content) {
        try {
            const data = JSON.parse(content);
            if (data.auth_mode)
                root.tierLabel = data.auth_mode;
        } catch (e) {
            console.log("model-usage/codex", "Failed to parse auth.json:", e);
        }
    }

    function scanSessions() {
        sessionLister.running = true;
    }

    function parseSessionList(output) {
        if (!output)
            return;
        const lines = output.trim().split("\n");
        const unique = {};
        for (let i = 0; i < lines.length; i++) {
            const file = lines[i].trim();
            if (!file.endsWith(".jsonl"))
                continue;
            unique[file] = true;
        }

        const files = Object.keys(unique).sort();
        if (files.length === 0) {
            root.sessionPaths = [];
            root.sessionPathIndex = -1;
            root.sessionSearchInProgress = false;
            return;
        }

        root.sessionPaths = files.slice(Math.max(0, files.length - 16));
        root.sessionPathIndex = root.sessionPaths.length - 1;
        root.sessionSearchInProgress = true;
        const newestPath = root.sessionPaths[root.sessionPathIndex];
        if (root.latestSessionPath === newestPath)
            latestSessionFile.reload();
        else
            root.latestSessionPath = newestPath;
    }

    function loadPreviousSessionFile() {
        if (!root.sessionSearchInProgress)
            return;
        root.sessionPathIndex = root.sessionPathIndex - 1;
        if (root.sessionPathIndex >= 0) {
            root.latestSessionPath = root.sessionPaths[root.sessionPathIndex];
        } else {
            root.sessionSearchInProgress = false;
        }
    }

    function parseSessionData(content) {
        try {
            const lines = content.split("\n");
            let latestUsageTokenCount = null;
            let latestRateLimits = null;
            let latestPlanType = "";

            for (let i = lines.length - 1; i >= 0; i--) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    let candidate = null;
                    if (entry.type === "event_msg" && entry.payload?.type === "token_count")
                        candidate = entry.payload;
                    else if (entry.type === "token_count")
                        candidate = entry;
                    else if (entry.type === "response_item" && entry.payload?.type === "event_msg" && entry.payload?.payload?.type === "token_count")
                        candidate = entry.payload.payload;

                    if (!candidate)
                        continue;

                    if (!latestUsageTokenCount && candidate.info?.total_token_usage)
                        latestUsageTokenCount = candidate;

                    if (!latestRateLimits && (candidate.rate_limits?.primary || candidate.rate_limits?.secondary)) {
                        latestRateLimits = candidate.rate_limits;
                        latestPlanType = candidate.rate_limits?.plan_type ?? "";
                    }

                    if (latestUsageTokenCount && latestRateLimits)
                        break;
                } catch (e) {
                    continue;
                }
            }

            if (!latestUsageTokenCount && !latestRateLimits) {
                root.loadPreviousSessionFile();
                return;
            }

            if (!root.tierLabel && latestPlanType)
                root.tierLabel = latestPlanType;

            const primary = latestRateLimits?.primary ?? null;
            if (primary) {
                root.rateLimitPercent = (primary.used_percent ?? 0) / 100;
                root.rateLimitLabel = root.labelForWindow(primary.window_minutes);
                root.rateLimitDetailText = Math.round((primary.used_percent ?? 0)) + "% used";
                root.rateLimitResetAt = primary.resets_at ? new Date(primary.resets_at * 1000).toISOString() : "";
            } else {
                root.rateLimitPercent = -1;
                root.rateLimitLabel = "5h window";
                root.rateLimitDetailText = "";
                root.rateLimitResetAt = "";
            }

            const secondary = latestRateLimits?.secondary ?? null;
            if (secondary) {
                root.secondaryRateLimitPercent = (secondary.used_percent ?? 0) / 100;
                root.secondaryRateLimitLabel = root.labelForWindow(secondary.window_minutes);
                root.secondaryRateLimitDetailText = Math.round((secondary.used_percent ?? 0)) + "% used";
                root.secondaryRateLimitResetAt = secondary.resets_at ? new Date(secondary.resets_at * 1000).toISOString() : "";
            } else {
                root.secondaryRateLimitPercent = -1;
                root.secondaryRateLimitLabel = "";
                root.secondaryRateLimitDetailText = "";
                root.secondaryRateLimitResetAt = "";
            }

            const usage = latestUsageTokenCount?.info?.total_token_usage;
            if (usage) {
                const input = usage.input_tokens ?? 0;
                const output = usage.output_tokens ?? 0;
                const cached = usage.cached_input_tokens ?? 0;
                const reasoning = usage.reasoning_output_tokens ?? 0;
                root.todayTotalTokens = input + output + cached + reasoning;

                const modelName = root.configModel || "codex";
                root.todayTokensByModel = {};
                root.todayTokensByModel[modelName] = root.todayTotalTokens;

                root.modelUsage = {};
                root.modelUsage[modelName] = {
                    inputTokens: input,
                    outputTokens: output + reasoning,
                    cacheReadInputTokens: cached,
                    cacheCreationInputTokens: 0
                };
            }

            root.sessionSearchInProgress = false;
        } catch (e) {
            console.log("model-usage/codex", "Failed to parse session data:", e);
            root.loadPreviousSessionFile();
        }
    }

    function refresh() {
        historyFile.reload();
        configFile.reload();
        authFile.reload();
        root.scanSessions();
    }

    function formatResetTime(isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const reset = new Date(isoTimestamp);
        const now = new Date();
        const diffMs = reset.getTime() - now.getTime();
        if (diffMs <= 0)
            return "now";
        const hours = Math.floor(diffMs / 3600000);
        const mins = Math.floor((diffMs % 3600000) / 60000);
        if (hours > 24)
            return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + mins + "m";
        return mins + "m";
    }
}
