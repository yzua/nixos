import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property var mainInstance: pluginApi?.mainInstance
    readonly property color sectionBackgroundColor: Color.mSurfaceVariant
    readonly property color usageWarnColor: Qt.alpha(Color.mError, 0.72)

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 460 * Style.uiScaleRatio
    property real contentPreferredHeight: 640 * Style.uiScaleRatio

    anchors.fill: parent

    property int selectedTabIndex: 0
    property var selectedProvider: {
        const ep = mainInstance?.enabledProviders ?? [];
        if (ep.length === 0)
            return null;
        return ep[Math.min(selectedTabIndex, ep.length - 1)];
    }

    function percentLeftText(value) {
        if (!(value >= 0))
            return "—";
        return Math.max(0, 100 - Math.round(value * 100)) + "% left";
    }

    function percentUsedText(value) {
        if (!(value >= 0))
            return "";
        return Math.round(value * 100) + "% used";
    }

    function limitResetSummary(provider, isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const relative = provider?.formatResetTime(isoTimestamp) ?? "";
        return relative ? ("Resets in " + relative) : "";
    }

    function overviewItems(provider) {
        if (!provider)
            return [];

        const items = [];
        const accountValue = provider.accountLabel ?? "";
        const planValue = provider.planLabel || provider.tierLabel || "";
        const modelValue = provider.currentModelLabel || provider.authModeLabel || "";

        if (accountValue) {
            items.push({
                label: "Account",
                value: accountValue,
                detail: provider.accountEmail && provider.accountEmail !== accountValue ? provider.accountEmail : (provider.organizationLabel ?? "")
            });
        }

        if (planValue) {
            items.push({
                label: "Plan",
                value: planValue,
                detail: provider.planDetail ?? ""
            });
        }

        if (modelValue) {
            items.push({
                label: provider.currentModelLabel ? "Model" : "Auth",
                value: modelValue,
                detail: provider.currentModelLabel && provider.authModeLabel ? provider.authModeLabel : ""
            });
        }

        if ((provider.rateLimitPercent ?? -1) >= 0) {
            items.push({
                label: provider.rateLimitLabel ?? "Limit",
                value: percentLeftText(provider.rateLimitPercent),
                detail: (provider.rateLimitDetailText ?? "") || (percentUsedText(provider.rateLimitPercent) + (limitResetSummary(provider, provider.rateLimitResetAt) ? (" • " + limitResetSummary(provider, provider.rateLimitResetAt)) : ""))
            });
        }

        if ((provider.secondaryRateLimitPercent ?? -1) >= 0) {
            items.push({
                label: provider.secondaryRateLimitLabel ?? "Secondary limit",
                value: percentLeftText(provider.secondaryRateLimitPercent),
                detail: (provider.secondaryRateLimitDetailText ?? "") || (percentUsedText(provider.secondaryRateLimitPercent) + (limitResetSummary(provider, provider.secondaryRateLimitResetAt) ? (" • " + limitResetSummary(provider, provider.secondaryRateLimitResetAt)) : ""))
            });
        }

        return items;
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: 0

            NTabBar {
                id: tabBar
                Layout.fillWidth: true
                visible: (mainInstance?.enabledProviders ?? []).length > 1

                Repeater {
                    model: mainInstance?.enabledProviders ?? []

                    NTabButton {
                        required property var modelData
                        required property int index
                        readonly property int tabCount: (mainInstance?.enabledProviders ?? []).length
                        text: modelData.providerName
                        width: tabCount > 0 ? Math.floor(tabBar.width / tabCount) : implicitWidth
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        checked: index === root.selectedTabIndex
                        onClicked: root.selectedTabIndex = index
                    }
                }
            }

            Item {
                height: Style.marginM
                Layout.fillWidth: true
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: contentLayout.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: contentLayout
                    width: parent.width
                    spacing: Style.marginL

                    NText {
                        visible: !root.selectedProvider
                        text: "No providers enabled. Enable providers in Settings."
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.topMargin: Style.marginXL
                    }

                    NText {
                        visible: root.selectedProvider && !root.selectedProvider.ready
                        text: root.selectedProvider ? (root.selectedProvider.providerName + " — waiting for data...") : ""
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.topMargin: Style.marginXL
                    }

                    RowLayout {
                        visible: !!root.selectedProvider
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon: root.selectedProvider?.providerIcon ?? "ai"
                            pointSize: Style.fontSizeXXXL
                            color: Color.mPrimary
                        }

                        NText {
                            text: (root.selectedProvider?.providerName ?? "") + " Usage"
                            pointSize: Style.fontSizeXL
                            font.weight: Style.fontWeightBold
                            color: Color.mOnSurface
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: (root.selectedProvider?.tierLabel ?? "") !== ""
                            color: Qt.alpha(Color.mPrimary, 0.15)
                            radius: Style.radiusXS
                            implicitWidth: tierText.implicitWidth + Style.marginL
                            implicitHeight: tierText.implicitHeight + Style.marginS

                            NText {
                                id: tierText
                                anchors.centerIn: parent
                                text: root.selectedProvider?.tierLabel ?? ""
                                pointSize: Style.fontSizeS
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }
                        }
                    }

                    Rectangle {
                        visible: !!root.selectedProvider
                        Layout.fillWidth: true
                        height: 1
                        color: Color.mOutline
                    }

                    Rectangle {
                        visible: !!root.selectedProvider && (root.selectedProvider?.usageStatusText ?? "") !== ""
                        Layout.fillWidth: true
                        color: Qt.alpha(Color.mError, 0.12)
                        radius: Style.radiusS
                        implicitHeight: authStatusColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: authStatusColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginXS

                            NText {
                                text: root.selectedProvider?.usageStatusText ?? ""
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mError
                            }

                            NText {
                                text: root.selectedProvider?.authHelpText ?? ""
                                pointSize: Style.fontSizeXS
                                color: Color.mOnSurfaceVariant
                            }
                        }
                    }

                    Rectangle {
                        visible: root.overviewItems(root.selectedProvider).length > 0
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: overviewColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: overviewColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: "Overview"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: Style.marginM
                                rowSpacing: Style.marginM

                                Repeater {
                                    model: root.overviewItems(root.selectedProvider)

                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        color: Qt.alpha(Color.mSurface, 0.42)
                                        radius: Style.radiusS
                                        implicitHeight: overviewCardColumn.implicitHeight + Style.marginL

                                        ColumnLayout {
                                            id: overviewCardColumn
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                top: parent.top
                                                margins: Style.marginM
                                            }
                                            spacing: Style.marginXXS

                                            NText {
                                                text: modelData.label ?? ""
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                            }

                                            NText {
                                                text: modelData.value ?? ""
                                                pointSize: Style.fontSizeM
                                                font.weight: Style.fontWeightBold
                                                color: Color.mOnSurface
                                                wrapMode: Text.Wrap
                                            }

                                            NText {
                                                visible: (modelData.detail ?? "") !== ""
                                                text: modelData.detail ?? ""
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.selectedProvider?.accountItems ?? []).length > 0
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: accountColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: accountColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: "Account & Access"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            Repeater {
                                model: root.selectedProvider?.accountItems ?? []

                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Style.marginXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NText {
                                            text: modelData.label ?? ""
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        NText {
                                            text: modelData.value ?? ""
                                            pointSize: Style.fontSizeS
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                            wrapMode: Text.Wrap
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    NText {
                                        visible: (modelData.detail ?? "") !== ""
                                        text: modelData.detail ?? ""
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.selectedProvider?.rateLimitPercent ?? -1) >= 0
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: rateLimitColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: rateLimitColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: "Rate Limit Usage"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    NText {
                                        text: root.selectedProvider?.rateLimitLabel ?? ""
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    NText {
                                        text: {
                                            const u = root.selectedProvider?.rateLimitPercent ?? -1;
                                            if (u < 0)
                                                return "\u2014";
                                            return Math.round(u * 100) + "%";
                                        }
                                        pointSize: Style.fontSizeS
                                        font.weight: Style.fontWeightBold
                                        color: {
                                            const u = root.selectedProvider?.rateLimitPercent ?? 0;
                                            if (u >= 0.9)
                                                return Color.mError;
                                            if (u >= 0.7)
                                                return root.usageWarnColor;
                                            return Color.mOnSurface;
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Qt.alpha(Color.mOutline, 0.2)
                                    radius: Style.radiusXXS

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        radius: Style.radiusXXS
                                        color: {
                                            const u = root.selectedProvider?.rateLimitPercent ?? 0;
                                            if (u >= 0.9)
                                                return Color.mError;
                                            if (u >= 0.7)
                                                return root.usageWarnColor;
                                            return Color.mPrimary;
                                        }
                                        width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.rateLimitPercent ?? 0))

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Style.animationNormal
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }

                                NText {
                                    visible: (root.selectedProvider?.rateLimitDetailText ?? "") !== ""
                                    text: root.selectedProvider?.rateLimitDetailText ?? ""
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }

                                NText {
                                    visible: (root.selectedProvider?.rateLimitResetAt ?? "") !== ""
                                    text: "Resets in " + (root.selectedProvider?.formatResetTime(root.selectedProvider?.rateLimitResetAt ?? "") ?? "")
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }
                            }

                            ColumnLayout {
                                visible: (root.selectedProvider?.secondaryRateLimitPercent ?? -1) >= 0
                                Layout.fillWidth: true
                                spacing: Style.marginXS

                                RowLayout {
                                    Layout.fillWidth: true
                                    NText {
                                        text: root.selectedProvider?.secondaryRateLimitLabel ?? ""
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    NText {
                                        text: {
                                            const u = root.selectedProvider?.secondaryRateLimitPercent ?? -1;
                                            if (u < 0)
                                                return "\u2014";
                                            return Math.round(u * 100) + "%";
                                        }
                                        pointSize: Style.fontSizeS
                                        font.weight: Style.fontWeightBold
                                        color: {
                                            const u = root.selectedProvider?.secondaryRateLimitPercent ?? 0;
                                            if (u >= 0.9)
                                                return Color.mError;
                                            if (u >= 0.7)
                                                return root.usageWarnColor;
                                            return Color.mOnSurface;
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    color: Qt.alpha(Color.mOutline, 0.2)
                                    radius: Style.radiusXXS

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            bottom: parent.bottom
                                        }
                                        radius: Style.radiusXXS
                                        color: {
                                            const u = root.selectedProvider?.secondaryRateLimitPercent ?? 0;
                                            if (u >= 0.9)
                                                return Color.mError;
                                            if (u >= 0.7)
                                                return root.usageWarnColor;
                                            return Color.mPrimary;
                                        }
                                        width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.secondaryRateLimitPercent ?? 0))

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Style.animationNormal
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }

                                NText {
                                    visible: (root.selectedProvider?.secondaryRateLimitDetailText ?? "") !== ""
                                    text: root.selectedProvider?.secondaryRateLimitDetailText ?? ""
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }

                                NText {
                                    visible: (root.selectedProvider?.secondaryRateLimitResetAt ?? "") !== ""
                                    text: "Resets in " + (root.selectedProvider?.formatResetTime(root.selectedProvider?.secondaryRateLimitResetAt ?? "") ?? "")
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.selectedProvider?.ready ?? false) && (root.selectedProvider?.hasLocalStats ?? false)
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: todayColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: todayColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: "Today"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXL

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: String(root.selectedProvider?.todayPrompts ?? 0)
                                        pointSize: Style.fontSizeXXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "prompts"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: String(root.selectedProvider?.todaySessions ?? 0)
                                        pointSize: Style.fontSizeXXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "sessions"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }
                            }

                            Repeater {
                                model: {
                                    const toks = root.selectedProvider?.todayTokensByModel ?? {};
                                    const result = [];
                                    for (const k in toks)
                                        result.push({
                                            modelId: k,
                                            count: toks[k]
                                        });
                                    return result;
                                }

                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NText {
                                        text: mainInstance?.friendlyModelName(modelData.modelId) ?? modelData.modelId
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    NText {
                                        text: (mainInstance?.formatTokenCount(modelData.count) ?? "0") + " tokens"
                                        pointSize: Style.fontSizeS
                                        font.weight: Style.fontWeightSemiBold
                                        color: Color.mOnSurface
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.selectedProvider?.recentDays ?? []).length > 0
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: weekColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: weekColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginS

                            NText {
                                text: "Last 7 Days"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXL

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: String(root.selectedProvider?.recentPrompts ?? 0)
                                        pointSize: Style.fontSizeXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "prompts"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: String(root.selectedProvider?.recentSessions ?? 0)
                                        pointSize: Style.fontSizeXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "sessions"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }
                            }

                            Repeater {
                                model: root.selectedProvider?.recentDays ?? []

                                RowLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NText {
                                        text: {
                                            const d = modelData.date;
                                            if (!d)
                                                return "";
                                            const dt = new Date(d + "T00:00:00");
                                            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                                            return days[dt.getDay()] + " " + String(dt.getMonth() + 1).padStart(2, "0") + "/" + String(dt.getDate()).padStart(2, "0");
                                        }
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                        Layout.preferredWidth: 55
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 12
                                        color: Qt.alpha(Color.mOutline, 0.2)
                                        radius: Style.radiusXXS

                                        Rectangle {
                                            anchors {
                                                left: parent.left
                                                top: parent.top
                                                bottom: parent.bottom
                                            }
                                            radius: Style.radiusXXS
                                            color: Color.mPrimary
                                            width: {
                                                const days = root.selectedProvider?.recentDays ?? [];
                                                let maxCount = 1;
                                                for (let i = 0; i < days.length; i++) {
                                                    if ((days[i]?.messageCount ?? 0) > maxCount)
                                                        maxCount = days[i].messageCount;
                                                }
                                                const count = modelData?.messageCount ?? 0;
                                                return parent.width * (count / maxCount);
                                            }

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: Style.animationNormal
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }

                                    NText {
                                        text: mainInstance?.formatTokenCount(modelData?.messageCount ?? 0) ?? "0"
                                        pointSize: Style.fontSizeXS
                                        font.weight: Style.fontWeightSemiBold
                                        color: Color.mOnSurface
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (root.selectedProvider?.extraUsageItems ?? []).length > 0
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: extraUsageColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: extraUsageColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: root.selectedProvider?.extraUsageTitle ?? "Extra usage"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            Repeater {
                                model: root.selectedProvider?.extraUsageItems ?? []

                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NText {
                                        text: mainInstance?.friendlyModelName(modelData?.label ?? "") ?? (modelData?.label ?? "")
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    NText {
                                        text: String(modelData?.count ?? 0)
                                        pointSize: Style.fontSizeS
                                        font.weight: Style.fontWeightSemiBold
                                        color: Color.mOnSurface
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: {
                            const usage = root.selectedProvider?.modelUsage ?? {};
                            return Object.keys(usage).length > 0;
                        }
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: allTimeColumn.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: allTimeColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginM

                            NText {
                                text: "All-Time"
                                pointSize: Style.fontSizeL
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mPrimary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginXL

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: mainInstance?.formatTokenCount(root.selectedProvider?.totalPrompts ?? 0) ?? "0"
                                        pointSize: Style.fontSizeXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "messages"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                ColumnLayout {
                                    spacing: Style.marginXXS
                                    NText {
                                        text: String(root.selectedProvider?.totalSessions ?? 0)
                                        pointSize: Style.fontSizeXL
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                    }
                                    NText {
                                        text: "sessions"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Color.mOutline
                            }

                            Repeater {
                                model: {
                                    const usage = root.selectedProvider?.modelUsage ?? {};
                                    const result = [];
                                    for (const k in usage)
                                        result.push({
                                            modelId: k,
                                            data: usage[k]
                                        });
                                    return result;
                                }

                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Style.marginXS

                                    NText {
                                        text: mainInstance?.friendlyModelName(modelData.modelId) ?? modelData.modelId
                                        pointSize: Style.fontSizeM
                                        font.weight: Style.fontWeightSemiBold
                                        color: Color.mOnSurface
                                    }

                                    GridLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Style.marginM
                                        columns: 2
                                        columnSpacing: Style.marginL
                                        rowSpacing: Style.marginXXS

                                        NText {
                                            text: "Input"
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                        NText {
                                            text: mainInstance?.formatTokenCount(modelData.data?.inputTokens ?? 0) ?? "0"
                                            pointSize: Style.fontSizeXS
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                        }

                                        NText {
                                            text: "Output"
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                        NText {
                                            text: mainInstance?.formatTokenCount(modelData.data?.outputTokens ?? 0) ?? "0"
                                            pointSize: Style.fontSizeXS
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                        }

                                        NText {
                                            text: "Cache Read"
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                        NText {
                                            text: mainInstance?.formatTokenCount(modelData.data?.cacheReadInputTokens ?? 0) ?? "0"
                                            pointSize: Style.fontSizeXS
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                        }

                                        NText {
                                            text: "Cache Write"
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                        NText {
                                            text: mainInstance?.formatTokenCount(modelData.data?.cacheCreationInputTokens ?? 0) ?? "0"
                                            pointSize: Style.fontSizeXS
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                        }
                                    }

                                    Item {
                                        height: Style.marginXS
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
