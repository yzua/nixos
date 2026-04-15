import QtQuick
import Quickshell
import Quickshell.Io
import "../ProviderUtils.js" as PU

Item {
    id: root
    visible: false

    property string providerId: "claude"
    property string providerName: "Claude Code"
    property string providerIcon: "ai"
    property bool enabled: false
    property bool ready: false
    property string usageStatusText: ""

    property real rateLimitPercent: -1
    property string rateLimitLabel: "Weekly (7-day)"
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: "Session (5-hour)"
    property string secondaryRateLimitResetAt: ""

    property int todayPrompts: 0
    property int todaySessions: 0
    property int todayTotalTokens: 0
    property var todayTokensByModel: ({})

    property var recentDays: []
    property int totalPrompts: 0
    property int totalSessions: 0
    property var modelUsage: ({})
    property var dailyActivity: []
    property string rateLimitDetailText: ""
    property string secondaryRateLimitDetailText: ""

    property string tierLabel: ""
    property string authHelpText: "Run `claude auth login` to restore authoritative usage."
    property bool hasLocalStats: true

    property string accountLabel: ""
    property string accountEmail: ""
    property string organizationLabel: ""
    property string organizationId: ""
    property string authModeLabel: ""
    property string planLabel: ""
    property string planDetail: ""
    property var accountItems: []

    property string oauthAccessToken: ""
    property double oauthExpiresAtMs: 0
    property string authMode: "none"
    property string subscriptionType: ""
    property string rateLimitTier: ""
    property bool hasAuthoritativeRateLimit: false

    property double lastProbeAtMs: 0
    property int probeMinIntervalMs: 5 * 60 * 1000

    property var providerSettings: ({})

    readonly property string _home: Quickshell.env("HOME") ?? "/home"

    function resolvePath(p) { return PU.resolvePath(p, _home) }

    FileView {
        id: statsFile
        path: root.resolvePath(root.providerSettings?.statsPath ?? "~/.claude/stats-cache.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseStats(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/claude", "stats-cache.json not found at", statsFile.path);
        }
    }

    FileView {
        id: historyFile
        path: root.resolvePath("~/.claude/history.jsonl")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseHistory(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/claude", "history.jsonl not found");
        }
    }

    FileView {
        id: credentialsFile
        path: root.resolvePath(root.providerSettings?.credentialsPath ?? "~/.claude/.credentials.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseCredentials(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                console.log("model-usage/claude", "credentials.json not found at", credentialsFile.path);
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: root.enabled && root.oauthAccessToken !== ""
        repeat: true
        onTriggered: root.probeRateLimits()
    }

    function localDateString() { return PU.localDateString() }

    function updateAccountItems() {
        const items = [];
        if (root.accountEmail)
            items.push({
                label: "Email",
                value: root.accountEmail
            });
        if (root.organizationLabel)
            items.push({
                label: "Organization",
                value: root.organizationLabel
            });
        if (root.authModeLabel)
            items.push({
                label: "Auth",
                value: root.authModeLabel
            });
        if (root.rateLimitTier)
            items.push({
                label: "Rate tier",
                value: PU.humanizeIdentifier(root.rateLimitTier.replace(/^default_/, ""))
            });
        if (root.planDetail)
            items.push({
                label: "Token expires",
                value: root.planDetail
            });
        if (root.organizationId)
            items.push({
                label: "Org ID",
                value: PU.shortId(root.organizationId),
                detail: root.organizationId
            });
        root.accountItems = items;
    }

    function parseStats(content) {
        try {
            const data = JSON.parse(content);
            const today = localDateString();

            const dailyModelTokens = data.dailyModelTokens ?? [];
            const todayTokenEntry = dailyModelTokens.find(d => d.date === today);
            root.todayTokensByModel = todayTokenEntry?.tokensByModel ?? {};

            let tokenSum = 0;
            const toks = root.todayTokensByModel;
            for (const k in toks)
                tokenSum += toks[k];
            root.todayTotalTokens = tokenSum;

            root.dailyActivity = data.dailyActivity ?? [];
            root.recentDays = root.dailyActivity.slice(-7);
            root.modelUsage = data.modelUsage ?? {};
            root.totalPrompts = data.totalMessages ?? 0;
            root.totalSessions = data.totalSessions ?? 0;
            root.ready = true;
        } catch (e) {
            console.log("model-usage/claude", "Failed to parse stats-cache.json:", e);
        }
    }

    function parseHistory(content) {
        try {
            const now = new Date();
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
            const lines = content.split("\n");
            let prompts = 0;
            const sessions = {};

            for (let i = lines.length - 1; i >= 0; i--) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    if ((entry.timestamp ?? 0) < startOfDay)
                        break;
                    prompts++;
                    if (entry.sessionId)
                        sessions[entry.sessionId] = true;
                } catch (e) {
                    continue;
                }
            }

            root.todayPrompts = prompts;
            root.todaySessions = Object.keys(sessions).length;
            root.ready = true;
        } catch (e) {
            console.log("model-usage/claude", "Failed to parse history.jsonl:", e);
        }
    }

    function parseCredentials(content) {
        try {
            const data = JSON.parse(content);
            const oauth = data.claudeAiOauth ?? {};
            const fileAccessToken = oauth.accessToken ?? "";
            const fileExpiresAtMs = root.normalizeExpiresAtMs(oauth.expiresAt);
            const fileHasOAuth = fileAccessToken !== "";

            const tokenChanged = (root.oauthAccessToken !== fileAccessToken || root.oauthExpiresAtMs !== fileExpiresAtMs);
            root.oauthAccessToken = fileAccessToken;
            root.oauthExpiresAtMs = fileExpiresAtMs;
            if (tokenChanged)
                root.clearAuthoritativeRateLimits();

            root.authMode = fileHasOAuth ? "oauth" : "none";

            root.subscriptionType = oauth.subscriptionType ?? "";
            root.rateLimitTier = oauth.rateLimitTier ?? "";
            root.planLabel = formatTier();
            root.tierLabel = root.planLabel;
            root.planDetail = PU.formatShortDate(root.oauthExpiresAtMs);
            root.authModeLabel = fileHasOAuth ? "claude.ai OAuth" : "No auth";
            root.updateAccountItems();

            if (root.oauthAccessToken && !root.oauthTokenExpired()) {
                root.clearUsageStatus();
                root.probeRateLimits();
            } else if (!root.oauthAccessToken) {
                root.usageStatusText = "Waiting for auth";
                root.clearAuthoritativeRateLimits();
            } else {
                root.usageStatusText = "Token expired";
                root.clearAuthoritativeRateLimits();
            }
        } catch (e) {
            console.log("model-usage/claude", "Failed to parse credentials.json:", e);
            root.usageStatusText = "Waiting for auth";
            root.clearAuthoritativeRateLimits();
        }
    }

    function formatTier() {
        if (!root.rateLimitTier)
            return root.subscriptionType || "";
        const match = root.rateLimitTier.match(/max_(\d+x)/i);
        if (match)
            return "Max " + match[1];
        if (root.subscriptionType)
            return root.subscriptionType.charAt(0).toUpperCase() + root.subscriptionType.slice(1);
        return PU.humanizeIdentifier(root.rateLimitTier.replace(/^default_/, ""));
    }

    function normalizeExpiresAtMs(value) {
        const n = Number(value ?? 0);
        return (isFinite(n) && n > 0) ? n : 0;
    }

    function oauthTokenExpired() {
        if (!root.oauthAccessToken)
            return true;
        if (!root.oauthExpiresAtMs || !(root.oauthExpiresAtMs > 0))
            return false;
        return root.oauthExpiresAtMs <= Date.now();
    }

    function clearAuthoritativeRateLimits() {
        root.hasAuthoritativeRateLimit = false;
        root.rateLimitPercent = -1;
        root.rateLimitLabel = "Weekly (7-day)";
        root.rateLimitResetAt = "";
        root.rateLimitDetailText = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "Session (5-hour)";
        root.secondaryRateLimitResetAt = "";
        root.secondaryRateLimitDetailText = "";
    }

    function clearUsageStatus() {
        root.usageStatusText = "";
    }

    function parseAuthStatus(rawText) {
        try {
            const data = JSON.parse(rawText ?? "{}");
            root.accountEmail = data.email ?? root.accountEmail;
            root.organizationLabel = data.orgName ?? "";
            root.organizationId = data.orgId ?? "";
            root.accountLabel = root.accountEmail || root.organizationLabel || "Claude account";
            if (data.subscriptionType) {
                root.subscriptionType = data.subscriptionType;
                root.planLabel = root.formatTier();
                root.tierLabel = root.planLabel;
            }
            if (data.authMethod)
                root.authModeLabel = data.authMethod === "claude.ai" ? "claude.ai OAuth" : PU.humanizeIdentifier(data.authMethod);
            root.updateAccountItems();
        } catch (e) {
            console.log("model-usage/claude", "Failed to parse auth status:", e);
        }
    }

    function parseNumber(value) {
        if (value === null || value === undefined)
            return NaN;
        return parseFloat(String(value).trim().replace("%", ""));
    }

    function normalizeUtilization(value) {
        const n = parseNumber(value);
        if (!(n >= 0))
            return -1;
        if (n > 1)
            return Math.min(1, n / 100);
        return Math.min(1, n);
    }

    function normalizeResetAt(value) { return PU.normalizeResetAt(value) }

    function oauthUsageBucket(payload, key) {
        const bucket = payload?.[key];
        if (bucket && typeof bucket === "object")
            return bucket;
        return null;
    }

    function applyAuthoritativeRateLimits(weekly, weeklyReset, session, sessionReset, sourceLabel) {
        const weeklyNorm = root.normalizeUtilization(weekly);
        const sessionNorm = root.normalizeUtilization(session);
        if (weeklyNorm < 0 && sessionNorm < 0)
            return false;

        root.hasAuthoritativeRateLimit = true;
        root.rateLimitPercent = -1;
        root.rateLimitLabel = "Weekly (7-day)";
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "Session (5-hour)";
        root.secondaryRateLimitResetAt = "";

        if (weeklyNorm >= 0)
            root.rateLimitPercent = weeklyNorm;
        if (sessionNorm >= 0)
            root.secondaryRateLimitPercent = sessionNorm;
        if (weeklyReset !== null && weeklyReset !== undefined)
            root.rateLimitResetAt = root.normalizeResetAt(weeklyReset);
        if (sessionReset !== null && sessionReset !== undefined)
            root.secondaryRateLimitResetAt = root.normalizeResetAt(sessionReset);

        if (root.rateLimitPercent < 0 && sessionNorm >= 0) {
            root.rateLimitPercent = sessionNorm;
            root.rateLimitLabel = root.secondaryRateLimitLabel;
            root.rateLimitResetAt = root.secondaryRateLimitResetAt;
        }

        if (sourceLabel)
            root.rateLimitLabel = root.rateLimitLabel + " (" + sourceLabel + ")";
        return true;
    }

    function probeOAuthUsage() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.anthropic.com/api/oauth/usage");
        xhr.setRequestHeader("Authorization", "Bearer " + root.oauthAccessToken);
        xhr.setRequestHeader("anthropic-beta", "oauth-2025-04-20");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const payload = JSON.parse(xhr.responseText ?? "{}");
                    const weeklyBucket = root.oauthUsageBucket(payload, "seven_day_oauth_apps") || root.oauthUsageBucket(payload, "seven_day");
                    const sessionBucket = root.oauthUsageBucket(payload, "five_hour");

                    if (root.applyAuthoritativeRateLimits(weeklyBucket?.utilization, weeklyBucket?.resets_at, sessionBucket?.utilization, sessionBucket?.resets_at, "")) {
                        root.rateLimitDetailText = root.rateLimitPercent >= 0 ? (Math.round(root.rateLimitPercent * 100) + "% used • " + Math.max(0, 100 - Math.round(root.rateLimitPercent * 100)) + "% left") : "";
                        root.secondaryRateLimitDetailText = root.secondaryRateLimitPercent >= 0 ? (Math.round(root.secondaryRateLimitPercent * 100) + "% used • " + Math.max(0, 100 - Math.round(root.secondaryRateLimitPercent * 100)) + "% left") : "";
                        root.clearUsageStatus();
                        return;
                    }
                } catch (e) {
                    console.log("model-usage/claude", "Failed to parse oauth usage response:", e);
                }
            }

            if (xhr.status === 401 || xhr.status === 403) {
                root.usageStatusText = "Token expired";
                root.clearAuthoritativeRateLimits();
                return;
            }

            const body = xhr.responseText ? String(xhr.responseText).slice(0, 220) : "";
            console.log("model-usage/claude", "OAuth usage probe failed (status " + xhr.status + ")" + (body ? " body=" + body : ""));
            root.clearAuthoritativeRateLimits();
        };
        xhr.send();
    }

    function refresh() {
        statsFile.reload();
        historyFile.reload();
        credentialsFile.reload();
        authStatusProcess.running = true;
    }

    function formatResetTime(isoTimestamp) { return PU.formatResetTime(isoTimestamp) }

    function probeRateLimits() {
        if (!root.oauthAccessToken || root.authMode !== "oauth") {
            root.usageStatusText = "Waiting for auth";
            root.clearAuthoritativeRateLimits();
            return;
        }

        if (root.oauthTokenExpired()) {
            root.usageStatusText = "Token expired";
            root.clearAuthoritativeRateLimits();
            return;
        }

        const nowMs = Date.now();
        if (root.lastProbeAtMs > 0 && (nowMs - root.lastProbeAtMs) < root.probeMinIntervalMs)
            return;
        root.lastProbeAtMs = nowMs;

        root.probeOAuthUsage();
    }

    Process {
        id: authStatusProcess
        command: ["claude", "auth", "status"]
        running: false
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode === 0 && stdout.text.trim())
                root.parseAuthStatus(stdout.text);
        }
    }

    onEnabledChanged: {
        if (enabled)
            authStatusProcess.running = true;
    }
}
