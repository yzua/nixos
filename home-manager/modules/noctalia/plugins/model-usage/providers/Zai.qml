import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property string providerId: "zai"
    property string providerName: "Z.ai"
    property string providerIcon: "activity"
    property bool enabled: false
    property bool ready: false

    // Primary rate limit: TOKENS_LIMIT
    property real rateLimitPercent: -1
    property string rateLimitLabel: "Token quota"
    property string rateLimitResetAt: ""

    // Secondary rate limit: TIME_LIMIT (MCP calls)
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: "MCP calls"
    property string secondaryRateLimitResetAt: ""

    property int todayPrompts: 0
    property int todaySessions: 0
    property int todayTotalTokens: 0
    property var todayTokensByModel: ({})

    property var recentDays: []
    property int totalPrompts: 0
    property int totalSessions: 0
    property var modelUsage: ({})

    property string tierLabel: ""
    property string authHelpText: "Place API key at /run/secrets/zai_api_key"
    property bool hasLocalStats: false

    property var providerSettings: ({})
    property string apiKeyPath: "/run/secrets/zai_api_key"

    property string _apiKey: ""
    property string _rawResponse: ""

    readonly property string endpoint: "https://api.z.ai/api/monitor/usage/quota/limit"

    function resolvePath(p) {
        if (p && p.startsWith("~"))
            return (Quickshell.env("HOME") ?? "/home") + p.substring(1);
        return p;
    }

    Process {
        id: keyReader
        command: ["cat", root.resolvePath(root.apiKeyPath)]
        running: false
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root._apiKey = stdout.text.trim();
            } else {
                root._apiKey = "";
            }
            root.ready = true;
            if (root._apiKey && root.enabled)
                root.fetchQuota();
            else if (!root._apiKey)
                root.usageStatusText = "API key not found";
        }
    }

    Process {
        id: fetchProcess
        command: ["curl", "-s", "-m", "8", "-f", root.endpoint,
            "-H", "Authorization: Bearer " + root._apiKey,
            "-H", "Content-Type: application/json"]
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode) {
            if (exitCode !== 0 || !stdout.text.trim()) {
                root.usageStatusText = "API unreachable";
                root.ready = true;
                return;
            }

            try {
                root._rawResponse = stdout.text.trim();
                root.parseResponse(root._rawResponse);
            } catch (e) {
                console.log("model-usage/zai", "Parse failed:", e);
                root.usageStatusText = "Bad response";
                root.ready = true;
            }
        }
    }

    property string usageStatusText: ""

    Timer {
        interval: root.providerSettings?.refreshIntervalSec ?? 120
        running: root.enabled
        repeat: true
        onTriggered: root.fetchQuota()
    }

    onEnabledChanged: {
        if (enabled) {
            keyReader.running = true;
        }
    }

    function fetchQuota() {
        if (!root._apiKey) {
            root.usageStatusText = "No API key";
            root.ready = true;
            return;
        }
        if (!fetchProcess.running) {
            root.usageStatusText = "";
            fetchProcess.running = true;
        }
    }

    function parseResponse(responseText) {
        const resp = JSON.parse(responseText);
        if (resp.code !== 200 || !resp.data) {
            root.usageStatusText = resp.msg || "API error";
            root.ready = true;
            return;
        }

        const data = resp.data;
        root.tierLabel = data.level || "";

        let tokenLimit = null;
        let timeLimit = null;

        const limits = data.limits || [];
        for (let i = 0; i < limits.length; i++) {
            if (limits[i].type === "TOKENS_LIMIT")
                tokenLimit = limits[i];
            else if (limits[i].type === "TIME_LIMIT")
                timeLimit = limits[i];
        }

        // Primary: token quota
        if (tokenLimit) {
            const pct = tokenLimit.percentage ?? 0;
            root.rateLimitPercent = pct / 100;
            root.rateLimitLabel = "Token quota (" + (tokenLimit.unit ?? "?") + "x " + (tokenLimit.number ?? "?") + ")";

            if (tokenLimit.nextResetTime) {
                root.rateLimitResetAt = new Date(tokenLimit.nextResetTime).toISOString();
            }

            // Estimate tokens from limit info
            // unit * number * 1M is approximate token allocation per period
            const estimatedTokens = (tokenLimit.unit || 0) * (tokenLimit.number || 0) * 1000000;
            const usedTokens = Math.round(estimatedTokens * (pct / 100));
            root.todayTotalTokens = usedTokens;
            root.todayTokensByModel = { "glm-coding": usedTokens };
            root.modelUsage = { "glm-coding": { inputTokens: usedTokens, outputTokens: 0, cacheReadInputTokens: 0, cacheCreationInputTokens: 0 } };
        } else {
            root.rateLimitPercent = -1;
            root.rateLimitResetAt = "";
        }

        // Secondary: MCP time limit
        if (timeLimit) {
            const pct = timeLimit.percentage ?? 0;
            root.secondaryRateLimitPercent = pct / 100;
            root.secondaryRateLimitLabel = "MCP calls (" + timeLimit.remaining + "/" + timeLimit.usage + ")";

            if (timeLimit.nextResetTime) {
                root.secondaryRateLimitResetAt = new Date(timeLimit.nextResetTime).toISOString();
            }

            // Build model usage from usageDetails
            const details = timeLimit.usageDetails || [];
            const usageByModel = {};
            for (let i = 0; i < details.length; i++) {
                usageByModel[details[i].modelCode] = details[i].usage;
            }
            // Show as "calls" in todayTokensByModel
            root.todayTokensByModel = {};
            for (const model in usageByModel) {
                root.todayTokensByModel[model] = usageByModel[model];
            }
        } else {
            root.secondaryRateLimitPercent = -1;
            root.secondaryRateLimitResetAt = "";
        }

        root.todayPrompts = timeLimit ? (timeLimit.currentValue || 0) : 0;
        root.todaySessions = 1;
        root.ready = true;
    }

    function reload() {
        if (root.enabled && root._apiKey)
            fetchQuota();
    }

    function refresh() {
        keyReader.running = true;
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
        const days = Math.floor(hours / 24);
        if (days > 0)
            return days + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + mins + "m";
        return mins + "m";
    }
}
