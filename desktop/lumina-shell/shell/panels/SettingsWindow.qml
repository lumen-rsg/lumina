// Navigation rail and content pane adapted from upstream ii/settings.qml.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ApplicationWindow {
    id: root
    title: "Lumina Settings"
    width: Math.min(1000, (Quickshell.screens[0]?.width ?? 1280) - 32)
    height: Math.min(730, (Quickshell.screens[0]?.height ?? 800) - 80)
    minimumWidth: Math.min(700, (Quickshell.screens[0]?.width ?? 1280) - 32)
    minimumHeight: Math.min(500, (Quickshell.screens[0]?.height ?? 800) - 80)
    color: Appearance.m3colors.m3background
    visible: false
    property int currentPage: 0
    property bool expanded: width > 760
    readonly property var pages: [
        {name: "Quick", icon: "instant_mix"}, {name: "General", icon: "browse"},
        {name: "Bar", icon: "toast"}, {name: "Background", icon: "texture"},
        {name: "Interface", icon: "bottom_app_bar"}, {name: "Services", icon: "settings"},
        {name: "Advanced", icon: "construction"}, {name: "About", icon: "info"}
    ]
    signal assistantRequested()
    function open(page) { if (page !== undefined) currentPage = page; visible = true; raise(); requestActivate(); }
    onClosing: event => { event.accepted = false; visible = false; }
    FileDialog {
        id: wallpaperPicker
        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: Config.options.background.wallpaperPath = selectedFile.toString()
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8
        focus: true
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_PageDown) { root.currentPage = (root.currentPage + 1) % root.pages.length; event.accepted = true; }
                if (event.key === Qt.Key_Backtab || event.key === Qt.Key_PageUp) { root.currentPage = (root.currentPage + root.pages.length - 1) % root.pages.length; event.accepted = true; }
            }
            if (event.key === Qt.Key_Escape) { root.visible = false; event.accepted = true; }
        }
        RowLayout {
            StyledText { text: "Settings"; font.pixelSize: 24; Layout.fillWidth: true; Layout.leftMargin: 10 }
            ActionButton { symbol: "close"; Accessible.name: "Close settings"; onClicked: root.visible = false }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
            ScrollView {
                id: navScroll
                Layout.preferredWidth: root.expanded ? 168 : 102
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
            NavigationRail {
                id: rail
                expanded: root.expanded
                width: navScroll.availableWidth
                NavigationRailExpandButton { downAction: () => { root.expanded = !root.expanded; } }
                NavigationRailTabArray {
                    Layout.leftMargin: rail.expanded ? 0 : 20
                    expanded: rail.expanded; currentIndex: root.currentPage
                    Repeater {
                        model: root.pages
                        NavigationRailButton {
                            required property int index; required property var modelData
                            expanded: rail.expanded; toggled: root.currentPage === index
                            baseSize: 56
                            showToggledHighlight: false; buttonText: modelData.name; buttonIcon: modelData.icon
                            Accessible.name: modelData.name + " settings"
                            onClicked: root.currentPage = index
                        }
                    }
                }
            }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainerLow; radius: 24
                ContentPage {
                    anchors.fill: parent; anchors.margins: 16
                    forceWidth: true; baseWidth: width - 12; bottomContentPadding: 24
                    StyledText { text: root.pages[root.currentPage].name; font.pixelSize: 32; Layout.topMargin: 12 }
                    ContentSection {
                        visible: root.currentPage === 0 || root.currentPage === 3
                        title: "Wallpaper & colors"; icon: "format_paint"
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 180; radius: 18; color: Appearance.colors.colLayer2; clip: true
                            Image { anchors.fill: parent; source: Config.options.background.wallpaperPath; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            ActionButton { label: "Choose file"; symbol: "wallpaper"; onClicked: wallpaperPicker.open() }
                            ActionButton { label: "Cassiopeia"; symbol: "restore"; onClicked: Config.options.background.wallpaperPath = "/usr/share/backgrounds/lumina/lumina-default.png" }
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            Repeater {
                                model: [{key: "cassiopeia", label: "Cassiopeia", color: "#c3b8ff"}, {key: "forest", label: "Muted forest", color: "#A8C7A0"}, {key: "sandy", label: "Sandy", color: "#EECC92"}]
                                ActionButton {
                                    required property var modelData
                                    label: modelData.label; symbol: "palette"
                                    toggled: Config.options.appearance.theme === modelData.key
                                    onClicked: Appearance.selectTheme(modelData.key)
                                    Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; width: 32; height: 3; radius: 1; color: parent.modelData.color }
                                }
                            }
                        }
                        StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Forest uses deep evergreen; Sandy uses warm light surfaces. Light and Dark select Cassiopeia's corresponding palette."; font.pixelSize: 12; opacity: 0.7 }
                        RowLayout {
                            Layout.fillWidth: true
                            ControlTile { Layout.fillWidth: true; label: "Light"; symbol: "light_mode"; toggled: !Appearance.m3colors.darkmode; onActivated: { Appearance.selectTheme("cassiopeia"); Config.options.appearance.dark = false; } }
                            ControlTile { Layout.fillWidth: true; label: "Dark"; symbol: "dark_mode"; toggled: Appearance.m3colors.darkmode; onActivated: { Appearance.selectTheme("cassiopeia"); Config.options.appearance.dark = true; } }
                        }
                        StyledText { visible: root.currentPage === 3; Layout.fillWidth: true; text: Config.options.background.wallpaperPath; wrapMode: Text.WrapAnywhere; font.pixelSize: 12; opacity: 0.6 }
                    }
                    ContentSection {
                        visible: root.currentPage === 0 || root.currentPage === 4
                        title: "Control center"; icon: "instant_mix"
                        PreferenceSwitch { text: "Show microphone slider"; buttonIcon: "mic"; value: Config.options.controls.showMic; onEdited: if (checked !== Config.options.controls.showMic) Config.options.controls.showMic = checked }
                        PreferenceSwitch { text: "Show brightness when a backlight is available"; buttonIcon: "light_mode"; value: Config.options.controls.showBrightness; onEdited: if (checked !== Config.options.controls.showBrightness) Config.options.controls.showBrightness = checked }
                        PreferenceSwitch { text: "Show Calendar / To Do / Timer"; buttonIcon: "calendar_month"; value: Config.options.controls.showCalendar; onEdited: if (checked !== Config.options.controls.showCalendar) Config.options.controls.showCalendar = checked }
                        PreferenceSwitch { text: "Show media controls"; buttonIcon: "music_note"; value: Config.options.controls.showMedia; onEdited: Config.options.controls.showMedia = checked }
                    }
                    ContentSection {
                        visible: root.currentPage === 1
                        title: "Devices & connections"; icon: "devices"
                        SettingLink { label: "Network"; detail: Controls.state.connection; symbol: "wifi"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                        SettingLink { label: "Bluetooth"; detail: "Pair and manage devices"; symbol: "bluetooth"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                        SettingLink { label: "Sound"; detail: "Outputs, inputs and application volumes"; symbol: "speaker"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
                        SettingLink { label: "Displays"; detail: "Resolution, scale and arrangement"; symbol: "monitor"; onClicked: Quickshell.execDetached(["wdisplays"]) }
                    }
                    ContentSection {
                        visible: root.currentPage === 1
                        title: "Power"; icon: "battery_full"
                        StyledText { text: Controls.state.powerProfile ? "Current profile: " + Controls.state.powerProfile : "Power profiles are unavailable on this device"; Layout.fillWidth: true; wrapMode: Text.Wrap }
                        RowLayout {
                            Layout.fillWidth: true
                            Repeater { model: ["power-saver", "balanced", "performance"]
                                ActionButton { required property string modelData; label: modelData; enabled: !Controls.busy && Controls.state.powerProfile !== ""; toggled: Controls.state.powerProfile === modelData; onClicked: Controls.set("profile", modelData) }
                            }
                        }
                        StyledText { visible: Controls.error !== ""; text: Controls.error; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Appearance.m3colors.m3error }
                    }
                    ContentSection {
                        visible: root.currentPage === 2
                        title: "Bar modules"; icon: "toast"
                        PreferenceSwitch { text: "Show module labels"; buttonIcon: "label"; value: Config.options.bar.verbose; onEdited: if (checked !== Config.options.bar.verbose) Config.options.bar.verbose = checked }
                        PreferenceSwitch { text: "Show assistant shortcut"; buttonIcon: "auto_awesome"; value: Config.options.bar.showAssistant; onEdited: if (checked !== Config.options.bar.showAssistant) Config.options.bar.showAssistant = checked }
                        PreferenceSwitch { text: "Show system tray"; buttonIcon: "apps"; value: Config.options.bar.showTray; onEdited: if (checked !== Config.options.bar.showTray) Config.options.bar.showTray = checked }
                        PreferenceSwitch { text: "Use 24-hour clock"; buttonIcon: "schedule"; value: Config.options.bar.clock24h; onEdited: if (checked !== Config.options.bar.clock24h) Config.options.bar.clock24h = checked }
                    }
                    ContentSection {
                        visible: root.currentPage === 4
                        title: "Appearance"; icon: "palette"
                        PreferenceSwitch { text: "Transparent panels"; buttonIcon: "opacity"; value: Config.options.appearance.transparency.enable; onEdited: if (checked !== Config.options.appearance.transparency.enable) Config.options.appearance.transparency.enable = checked }
                        ControlSlider { Layout.fillWidth: true; label: "Panel transparency"; symbol: "opacity"; enabled: Config.options.appearance.transparency.enable; value: Config.options.appearance.transparency.backgroundTransparency; onMoved: value => Config.options.appearance.transparency.backgroundTransparency = Math.min(value, 0.8) }
                        PreferenceSwitch { text: "Reduce motion"; buttonIcon: "animation"; value: Config.options.appearance.reducedMotion; onEdited: if (checked !== Config.options.appearance.reducedMotion) Config.options.appearance.reducedMotion = checked }
                        StyledText { text: "Interface font"; font.pixelSize: 14 }
                        InputField { Layout.fillWidth: true; text: Config.options.appearance.fonts.main; Accessible.name: "Interface font"; onEditingFinished: if (text.trim()) Config.options.appearance.fonts.main = text.trim() }
                    }
                    ContentSection {
                        visible: root.currentPage === 5
                        title: "Notifications"; icon: "notifications"
                        PreferenceSwitch { text: "Do not disturb"; buttonIcon: "notifications_paused"; value: Config.options.notifications.dnd; onEdited: if (checked !== Config.options.notifications.dnd) Config.options.notifications.dnd = checked }
                        StyledText { text: "Popup duration"; font.pixelSize: 14 }
                        RowLayout {
                            Repeater { model: [3000, 6000, 10000]
                                ActionButton { required property int modelData; label: (modelData / 1000) + " seconds"; toggled: Config.options.notifications.timeout === modelData; onClicked: Config.options.notifications.timeout = modelData }
                            }
                        }
                    }
                    ContentSection {
                        visible: root.currentPage === 5
                        title: "Assistant"; icon: "auto_awesome"
                        StyledText { text: "Choose your provider, model and credentials in the assistant. No messages are sent until you configure a provider and press Send."; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 14 }
                        ActionButton { label: "Configure assistant"; symbol: "arrow_forward"; onClicked: { root.visible = false; root.assistantRequested(); } }
                    }
                    ContentSection {
                        visible: root.currentPage === 5
                        title: "Focus timer"; icon: "timer"
                        StyledText { text: "Minutes per session. Changes apply after Reset or at the next session."; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 13 }
                        RowLayout {
                            Layout.fillWidth: true
                            Repeater { model: [{label: "Focus", key: "focusMinutes"}, {label: "Break", key: "breakMinutes"}, {label: "Long break", key: "longBreakMinutes"}]
                                ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    StyledText { text: modelData.label; font.pixelSize: 12 }
                                    SpinBox { Layout.fillWidth: true; from: 1; to: 180; value: Productivity.data[modelData.key]; enabled: Productivity.ready; onValueModified: Productivity.data[modelData.key] = value }
                                }
                            }
                        }
                        StyledText { text: "A long break follows every fourth focus session."; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12; opacity: 0.65 }
                    }
                    ContentSection {
                        visible: root.currentPage === 6
                        title: "Configuration"; icon: "code"
                        StyledText { text: "Changes are saved automatically and apply immediately."; Layout.fillWidth: true; wrapMode: Text.Wrap }
                        StyledText { text: Config.configDir + "/shell.json"; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; font.pixelSize: 13; opacity: 0.7 }
                        ActionButton { label: "Open configuration folder"; symbol: "folder_open"; onClicked: Qt.openUrlExternally("file://" + Config.configDir) }
                        PreferenceSwitch { text: "Smooth mouse-wheel scrolling"; buttonIcon: "mouse"; value: Config.options.interactions.scrolling.fasterTouchpadScroll; onEdited: if (checked !== Config.options.interactions.scrolling.fasterTouchpadScroll) Config.options.interactions.scrolling.fasterTouchpadScroll = checked }
                    }
                    ContentSection {
                        visible: root.currentPage === 7
                        title: "Lumina"; icon: "flare"
                        StyledText { text: "26.9 · Cassiopeia"; font.pixelSize: 28 }
                        StyledText { text: "Chroma desktop\nBased on Fedora 44\nShell components and layouts derived from end-4's illogical-impulse dotfiles.\nGPL-3.0-only"; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 15 }
                        ActionButton { label: "Lumina source"; symbol: "code"; onClicked: Qt.openUrlExternally("https://github.com/lumen-rsg/lumina") }
                    }
                }
            }
        }
    }
    component SettingLink: ActionButton {
        property string detail
        Layout.fillWidth: true; implicitHeight: 68
        contentItem: RowLayout {
            spacing: 14
            MaterialSymbol { text: symbol; iconSize: 24 }
            ColumnLayout { Layout.fillWidth: true; spacing: 4
                StyledText { text: label; font.pixelSize: 16 }
                StyledText { text: detail; font.pixelSize: 12; opacity: 0.65 }
            }
            MaterialSymbol { text: "open_in_new"; iconSize: 18 }
        }
    }
}
