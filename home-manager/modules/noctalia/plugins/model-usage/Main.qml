import QtQuick
import Quickshell
import "providers"

Item {
    id: root
    visible: false

    property var pluginApi: null
    property var pluginSettings: pluginApi?.pluginSettings ?? ({})

    property var claudeProvider: claudeLoader.item
    property var codexProvider: codexLoader.item
    property var openRouterProvider: openRouterLoader.item
    property var copilotProvider: copilotLoader.item
    property var zenProvider: zenLoader.item
    property var zaiProvider: zaiLoader.item

    Loader {
        id: claudeLoader
        active: root.providerEnabled("claude")
        sourceComponent: Claude {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.claude ?? ({})
        }
    }

    Loader {
        id: codexLoader
        active: root.providerEnabled("codex")
        sourceComponent: Codex {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.codex ?? ({})
        }
    }

    Loader {
        id: openRouterLoader
        active: root.providerEnabled("openrouter")
        sourceComponent: OpenRouter {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.openrouter ?? ({})
        }
    }

    Loader {
        id: copilotLoader
        active: root.providerEnabled("copilot")
        sourceComponent: Copilot {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.copilot ?? ({})
        }
    }

    Loader {
        id: zenLoader
        active: root.providerEnabled("zen")
        sourceComponent: Zen {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.zen ?? ({})
        }
    }

    Loader {
        id: zaiLoader
        active: root.providerEnabled("zai")
        sourceComponent: Zai {
            enabled: true
            providerSettings: root.pluginSettings?.providers?.zai ?? ({})
        }
    }

    property var providers: [codexProvider, zaiProvider, claudeProvider, copilotProvider, openRouterProvider, zenProvider].filter(Boolean)

    property var enabledProviders: {
        const result = [];
        if (codexProvider)
            result.push(codexProvider);
        if (zaiProvider)
            result.push(zaiProvider);
        if (claudeProvider)
            result.push(claudeProvider);
        if (copilotProvider)
            result.push(copilotProvider);
        if (openRouterProvider)
            result.push(openRouterProvider);
        if (zenProvider)
            result.push(zenProvider);
        return result;
    }

    property int activeIndex: 0
    property var activeProvider: {
        if (enabledProviders.length === 0)
            return null;

        const indexed = enabledProviders[Math.min(activeIndex, enabledProviders.length - 1)];
        if (root.providerHasDisplayData(indexed))
            return indexed;

        for (const provider of enabledProviders) {
            if (root.providerHasDisplayData(provider))
                return provider;
        }

        return indexed;
    }

    property string barDisplayMode: pluginSettings?.barDisplayMode ?? "active"
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property string barMetric: pluginSettings?.barMetric ?? "prompts"
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 30

    Timer {
        interval: root.barCycleIntervalSec * 1000
        running: root.barDisplayMode === "cycle" && root.enabledProviders.length > 1
        repeat: true
        onTriggered: {
            root.activeIndex = (root.activeIndex + 1) % root.enabledProviders.length;
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    onEnabledProvidersChanged: {
        if (enabledProviders.length === 0) {
            activeIndex = 0;
        } else if (activeIndex >= enabledProviders.length) {
            activeIndex = 0;
        }
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll();
    }

    function refreshAll() {
        for (const p of providers) {
            if (p.enabled)
                p.refresh();
        }
    }

    function providerHasDisplayData(provider) {
        if (!provider)
            return false;
        if ((provider.rateLimitPercent ?? -1) >= 0)
            return true;
        if ((provider.todayPrompts ?? 0) > 0)
            return true;
        if ((provider.todayTotalTokens ?? 0) > 0)
            return true;
        if ((provider.usageStatusText ?? "") !== "")
            return true;
        return provider.ready === true;
    }

    function formatTokenCount(n) {
        if (n === undefined || n === null)
            return "0";
        if (n >= 1e9)
            return (n / 1e9).toFixed(1) + "B";
        if (n >= 1e6)
            return (n / 1e6).toFixed(1) + "M";
        if (n >= 1e3)
            return (n / 1e3).toFixed(1) + "K";
        return String(n);
    }

    function friendlyModelName(id) {
        if (!id)
            return "Unknown";
        if (id === "chatgpt")
            return "ChatGPT";
        let name = id.replace(/^claude-/, "");
        name = name.replace(/-\d{8}$/, "");
        const parts = name.split("-");
        if (parts.length >= 3) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1] + "." + parts[2];
        }
        if (parts.length === 2) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1];
        }
        if (name.indexOf(".") >= 0)
            return name.split(".").map(part => part ? (part.charAt(0).toUpperCase() + part.slice(1)) : "").join(".");
        if (name.indexOf("-") >= 0)
            return name.split("-").map(part => part ? (part.charAt(0).toUpperCase() + part.slice(1)) : "").join(" ");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }
}
