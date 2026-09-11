//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import "modules/common"
import "modules/common/widgets"
import "services"
import "panels"

ShellRoot {
    id: root
    property string panel: ""
    property var panelScreen: Quickshell.screens[0]
    property bool dnd: false
    property var notices: []
    function toggle(name, screen) {
        if (screen) panelScreen = screen;
        panel = panel === name ? "" : name;
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    NotificationServer {
        id: notifications
        bodySupported: true
        actionsSupported: true
        onNotification: notice => {
            notice.tracked = true;
            root.notices = root.notices.concat([notice]);
            if (!root.dnd) toastTimer.restart();
        }
    }
    Timer { id: toastTimer; interval: 6000 }
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property var modelData
            PanelWindow {
                screen: modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "lumina:background"
                color: "#11121f"
                Image { anchors.fill: parent; source: Config.options.background.wallpaperPath; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Column {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 48 }
                    spacing: 6
                    StyledText { text: "lumina"; font.pixelSize: 46; color: "#e7e7f7" }
                    StyledText { text: "26.9  /  CASSIOPEIA"; font.pixelSize: 13; font.letterSpacing: 3; color: "#c3b8ff" }
                }
            }
            PanelWindow {
                id: bar
                screen: modelData
                anchors { left: true; right: true; top: true }
                implicitHeight: 58
                exclusiveZone: 58
                color: "transparent"
                WlrLayershell.namespace: "lumina:bar"
                Rectangle {
                    anchors.fill: parent; anchors.margins: 6
                    color: Appearance.colors.colLayer0
                    radius: 22
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 4
                        ActionButton { label: "lumina"; onClicked: root.toggle("launcher", bar.screen) }
                        ActionButton { symbol: "grid_view"; label: bar.width > 900 ? "Canvas" : ""; onClicked: root.toggle("overview", bar.screen) }
                        ActionButton { symbol: "auto_awesome"; label: bar.width > 1000 ? "Assistant" : ""; onClicked: root.toggle("assistant", bar.screen) }
                        StyledText { Layout.fillWidth: true; text: Chroma.state.focused?.title || "Cassiopeia"; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; opacity: 0.8 }
                        Repeater {
                            model: SystemTray.items
                            delegate: ActionButton {
                                required property var modelData
                                implicitWidth: 34
                                Accessible.name: modelData.title || modelData.id
                                contentItem: Image { source: modelData.icon; sourceSize.width: 20; sourceSize.height: 20; fillMode: Image.PreserveAspectFit }
                                onClicked: modelData.activate(bar, 0, bar.height)
                                altAction: () => modelData.display(bar, 0, bar.height)
                            }
                        }
                        ActionButton { symbol: "volume_up"; label: bar.width > 1050 ? Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%" : ""; onClicked: root.toggle("settings", bar.screen) }
                        StyledText { visible: UPower.displayDevice.isLaptopBattery && bar.width > 700; text: Math.round(UPower.displayDevice.percentage * 100) + "%"; font.pixelSize: 12 }
                        ActionButton { label: Qt.formatDateTime(clock.date, "hh:mm"); onClicked: root.toggle("clock", bar.screen) }
                        ActionButton { symbol: "notifications"; label: ""; Accessible.name: "Notifications"; onClicked: root.toggle("notifications", bar.screen) }
                        ActionButton { symbol: "power_settings_new"; label: ""; Accessible.name: "Session"; onClicked: root.toggle("session", bar.screen) }
                    }
                }
            }
        }
    }
    PanelWindow {
        id: drawer
        screen: root.panelScreen
        visible: root.panel !== ""
        anchors { right: true; top: true; bottom: true }
        margins.top: 6
        margins.bottom: 8
        margins.right: 8
        implicitWidth: Math.min(root.panelScreen?.width ?? 600, 600) - 16
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "lumina:drawer"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Rectangle {
            anchors.fill: parent
            radius: 26
            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colLayer0Border
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "CASSIOPEIA"; font.letterSpacing: 2; font.pixelSize: 11; opacity: 0.5; Layout.fillWidth: true }
                    ActionButton { symbol: "close"; label: "Close"; onClicked: root.panel = "" }
                }
                Loader {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    sourceComponent: root.panel === "assistant" ? assistantPanel : root.panel === "overview" ? overviewPanel : root.panel === "launcher" ? launcherPanel : root.panel === "session" ? sessionPanel : root.panel === "notifications" ? notificationPanel : root.panel === "clock" ? clockPanel : settingsPanel
                }
            }
            Keys.onEscapePressed: root.panel = ""
            focus: true
        }
    }
    PanelWindow {
        visible: toastTimer.running && !root.dnd && root.notices.length > 0 && root.panel !== "notifications"
        screen: root.panelScreen
        anchors { top: true; right: true }
        margins.top: 70; margins.right: 14
        implicitWidth: 360; implicitHeight: 100
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "lumina:notification"
        Rectangle {
            anchors.fill: parent; radius: 20; color: Appearance.colors.colLayer1
            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 8
                StyledText { width: parent.width; text: root.notices[root.notices.length - 1]?.summary || ""; elide: Text.ElideRight; textFormat: Text.PlainText }
                StyledText { width: parent.width; text: root.notices[root.notices.length - 1]?.body || ""; maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight; opacity: 0.7; textFormat: Text.PlainText }
            }
        }
    }
    Component { id: assistantPanel; AssistantPanel {} }
    Component { id: overviewPanel; OverviewPanel {} }
    Component { id: launcherPanel; LauncherPanel { onLaunched: root.panel = "" } }
    Component {
        id: sessionPanel
        ColumnLayout {
            spacing: 14
            StyledText { text: "Take a break"; font.pixelSize: 26 }
            ActionButton { label: "Lock"; symbol: "lock"; onClicked: { root.panel = ""; Quickshell.execDetached(["chroma-lock"]); } }
            ActionButton { label: "Suspend"; symbol: "bedtime"; onClicked: Quickshell.execDetached(["chroma-session-action", "suspend"]) }
            ActionButton { label: "Log out"; symbol: "logout"; onClicked: Quickshell.execDetached(["chroma-session-action", "logout"]) }
            ActionButton { label: "Restart"; symbol: "restart_alt"; onClicked: Quickshell.execDetached(["chroma-session-action", "reboot"]) }
            ActionButton { label: "Power off"; symbol: "power_settings_new"; onClicked: Quickshell.execDetached(["chroma-session-action", "poweroff"]) }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: settingsPanel
        ColumnLayout {
            spacing: 16
            StyledText { text: "Quick settings"; font.pixelSize: 26 }
            StyledText { text: "Volume" }
            Slider { Layout.fillWidth: true; from: 0; to: 1; value: Pipewire.defaultAudioSink?.audio?.volume ?? 0; onMoved: if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = value }
            ActionButton { label: Pipewire.defaultAudioSink?.audio?.muted ? "Unmute" : "Mute"; onClicked: if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted }
            ActionButton { label: "Audio devices"; symbol: "speaker"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
            ActionButton { label: "Network"; symbol: "wifi"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
            ActionButton { label: "Bluetooth"; symbol: "bluetooth"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
            ActionButton { label: "Displays"; symbol: "monitor"; onClicked: Quickshell.execDetached(["wdisplays"]) }
            ActionButton { label: "Screenshot"; symbol: "screenshot_region"; onClicked: { root.panel = ""; Quickshell.execDetached(["chroma-capture", "screenshot", "area"]); } }
            StyledText { text: "Wallpaper path" }
            InputField { Layout.fillWidth: true; text: Config.options.background.wallpaperPath; Accessible.name: "Wallpaper path"; onEditingFinished: Config.options.background.wallpaperPath = text }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: clockPanel
        ColumnLayout {
            StyledText { text: Qt.formatDateTime(clock.date, "hh:mm"); font.pixelSize: 64 }
            StyledText { text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy"); font.pixelSize: 20 }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: notificationPanel
        ColumnLayout {
            StyledText { text: "Notifications"; font.pixelSize: 26 }
            RowLayout {
                ActionButton { label: root.dnd ? "Enable alerts" : "Do not disturb"; onClicked: root.dnd = !root.dnd }
                ActionButton { label: "Clear all"; onClicked: { for (const n of root.notices) if (n) n.dismiss(); root.notices = []; } }
            }
            ListView {
                Layout.fillHeight: true; Layout.fillWidth: true; clip: true; spacing: 12
                model: root.notices
                delegate: Column {
                    required property var modelData
                    width: ListView.view.width
                    spacing: 6
                    StyledText { width: parent.width; text: modelData?.summary || ""; wrapMode: Text.Wrap; textFormat: Text.PlainText }
                    StyledText { width: parent.width; text: modelData?.body || ""; opacity: 0.7; wrapMode: Text.Wrap; textFormat: Text.PlainText }
                    Flow {
                        width: parent.width
                        Repeater { model: modelData?.actions || []; ActionButton { required property var modelData; label: modelData.text; onClicked: modelData.invoke() } }
                    }
                }
            }
        }
    }
    IpcHandler { target: "launcher"; function toggle(): void { root.toggle("launcher"); } }
    IpcHandler { target: "overview"; function toggle(): void { root.toggle("overview"); } }
    IpcHandler { target: "tiling"; function toggle(): void { root.toggle("overview"); } }
    IpcHandler { target: "assistant"; function toggle(): void { root.toggle("assistant"); } }
    IpcHandler { target: "settings"; function toggle(): void { root.toggle("settings"); } }
    IpcHandler { target: "notifications"; function toggle(): void { root.toggle("notifications"); } function dnd(): void { root.dnd = !root.dnd; } }
    IpcHandler { target: "clock"; function toggle(): void { root.toggle("clock"); } }
    IpcHandler { target: "session"; function menu(): void { root.toggle("session"); } }
    IpcHandler { target: "hints"; function toggle(): void { root.toggle("overview"); } }
    IpcHandler { target: "shell"; function close(): void { root.panel = ""; } function status(): string { return JSON.stringify({panel: root.panel, connected: Chroma.connected, version: "26.9", windows: Chroma.state.windows.length}); } }
}
