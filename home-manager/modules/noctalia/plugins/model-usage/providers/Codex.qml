import QtQuick
import Quickshell
import Quickshell.Io
import "../ProviderUtils.js" as PU

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

    property string accountLabel: ""
    property string accountName: ""
    property string accountEmail: ""
    property string accountId: ""
    property string authModeLabel: ""
    property string planLabel: ""
    property string planDetail: ""
    property string currentModelLabel: ""
    property var accountItems: []

    property string configModel: ""
    property var providerSettings: ({})

    readonly property string _home: Quickshell.env("HOME") ?? "/home"

    function resolvePath(p) { return PU.resolvePath(p, _home) }
    function localDateString() { return PU.localDateString() }
    function dateDaysAgoString(daysAgo) { return PU.dateDaysAgoString(daysAgo) }

    function humanizeAuthMode(mode) {
        if (!mode)
            return "";
        if (mode === "chatgpt")
            return "ChatGPT";
        return PU.humanizeIdentifier(mode);
    }

    function humanizePlan(plan) {
        if (!plan)
            return "";
        if (plan === "team")
            return "Team";
        if (plan === "business")
            return "Business";
        if (plan === "enterprise")
            return "Enterprise";
        if (plan === "plus")
            return "Plus";
        if (plan === "pro")
            return "Pro";
        return PU.humanizeIdentifier(plan);
    }

    function updateAccountItems() {
        const items = [];
        if (root.accountName)
            items.push({
                label: "Name",
                value: root.accountName
            });
        if (root.accountEmail)
            items.push({
                label: "Email",
                value: root.accountEmail
            });
        if (root.authModeLabel)
            items.push({
                label: "Auth",
                value: root.authModeLabel
            });
        if (root.currentModelLabel)
            items.push({
                label: "Model",
                value: root.currentModelLabel
            });
        if (root.accountId)
            items.push({
                label: "Account ID",
                value: PU.shortId(root.accountId),
                detail: root.accountId
            });
        if (root.planDetail)
            items.push({
                label: "Billing window",
                value: root.planDetail
            });
        root.accountItems = items;
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
            if (match) {
                root.configModel = match[1];
                root.currentModelLabel = match[1];
                root.updateAccountItems();
            }
        } catch (e) {
            console.log("model-usage/codex", "Failed to parse config.toml:", e);
        }
    }

    function parseAuth(content) {
        try {
            const data = JSON.parse(content);
            const idPayload = PU.parseJwtPayload(data.tokens?.id_token ?? "") ?? {};
            const accessPayload = PU.parseJwtPayload(data.tokens?.access_token ?? "") ?? {};
            const authPayload = idPayload["https://api.openai.com/auth"] ?? accessPayload["https://api.openai.com/auth"] ?? {};
            const profilePayload = accessPayload["https://api.openai.com/profile"] ?? {};

            root.authModeLabel = root.humanizeAuthMode(data.auth_mode ?? "");
            root.accountName = idPayload.name ?? "";
            root.accountEmail = idPayload.email ?? profilePayload.email ?? "";
            root.accountId = authPayload.chatgpt_account_id ?? data.tokens?.account_id ?? "";
            root.accountLabel = root.accountEmail || root.accountName || root.authModeLabel;

            const jwtPlan = authPayload.chatgpt_plan_type ?? "";
            if (jwtPlan) {
                root.planLabel = root.humanizePlan(jwtPlan);
                root.tierLabel = root.planLabel;
            } else if (root.authModeLabel && !root.tierLabel) {
                root.tierLabel = root.authModeLabel;
            }

            root.planDetail = PU.formatDateRange(authPayload.chatgpt_subscription_active_start ?? "", authPayload.chatgpt_subscription_active_until ?? "");
            root.updateAccountItems();
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

            if (latestPlanType) {
                root.planLabel = root.humanizePlan(latestPlanType);
                root.tierLabel = root.planLabel;
            }

            const primary = latestRateLimits?.primary ?? null;
            if (primary) {
                root.rateLimitPercent = (primary.used_percent ?? 0) / 100;
                root.rateLimitLabel = root.labelForWindow(primary.window_minutes);
                root.rateLimitDetailText = Math.round((primary.used_percent ?? 0)) + "% used • " + Math.max(0, 100 - Math.round(primary.used_percent ?? 0)) + "% left";
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
                root.secondaryRateLimitDetailText = Math.round((secondary.used_percent ?? 0)) + "% used • " + Math.max(0, 100 - Math.round(secondary.used_percent ?? 0)) + "% left";
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

            root.updateAccountItems();

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

    function formatResetTime(isoTimestamp) { return PU.formatResetTime(isoTimestamp) }
}
