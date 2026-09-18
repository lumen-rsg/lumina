// Layout adapted from upstream ii SidebarRightContent and AndroidQuickPanel.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ScrollView {
    id: root
    property var notices: []
    signal settingsRequested()
    signal sessionRequested()
    signal closeRequested()
    signal clearNotices()
    signal calendarRequested()
    contentWidth: availableWidth
    contentHeight: body.implicitHeight
    clip: true
    ScrollBar.vertical: StyledScrollBar {}
    ColumnLayout {
        id: body
        width: root.availableWidth
        spacing: 10
        Component.onCompleted: Controls.refresh()
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                color: Appearance.colors.colLayer1; radius: 20; implicitHeight: 38; Layout.fillWidth: true
                Row { anchors.centerIn: parent; spacing: 8
                    Image { source: "/usr/share/icons/hicolor/scalable/apps/lumina-logo.svg"; width: 22; height: 22; fillMode: Image.PreserveAspectFit }
                    StyledText { text: "Up " + (Controls.state.uptime || "…"); anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13 }
                }
            }
            ActionButton { symbol: "settings"; Accessible.name: "Open settings"; onClicked: root.settingsRequested() }
            ActionButton { symbol: "power_settings_new"; Accessible.name: "Session controls"; onClicked: root.sessionRequested() }
            ActionButton { symbol: "close"; Accessible.name: "Close control center"; onClicked: root.closeRequested() }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: sliders.implicitHeight + 14
            color: Appearance.colors.colLayer1; radius: 20
            ColumnLayout {
                id: sliders; anchors.fill: parent; anchors.margins: 7; spacing: 0
                ControlSlider { Layout.fillWidth: true; label: "Volume"; symbol: "volume_up"; enabled: !!Pipewire.defaultAudioSink?.audio; value: Pipewire.defaultAudioSink?.audio?.volume ?? 0; onMoved: value => Pipewire.defaultAudioSink.audio.volume = value }
                ControlSlider { Layout.fillWidth: true; visible: Config.options.controls.showMic; label: "Microphone"; symbol: "mic"; enabled: !!Pipewire.defaultAudioSource?.audio; value: Pipewire.defaultAudioSource?.audio?.volume ?? 0; onMoved: value => Pipewire.defaultAudioSource.audio.volume = value }
                ControlSlider { Layout.fillWidth: true; visible: Config.options.controls.showBrightness && Controls.state.brightness !== null; label: "Brightness"; symbol: "light_mode"; value: (Controls.state.brightness ?? 0) / 100; onMoved: value => Controls.set("brightness", Math.max(1, Math.round(value * 100))) }
            }
        }
        GridLayout {
            Layout.fillWidth: true; Layout.maximumHeight: 198; columns: 2; rowSpacing: 6; columnSpacing: 6
            ControlTile { Layout.fillWidth: true; label: "Internet"; detail: Controls.state.connection; symbol: "wifi"; hasMenu: true; toggled: Controls.state.wifiEnabled; onActivated: { if (Controls.state.wifiAvailable) Controls.set("wifi", Controls.state.wifiEnabled ? "off" : "on"); else openMenu(); } onOpenMenu: Quickshell.execDetached(["nm-connection-editor"]); enabled: !Controls.busy }
            ControlTile { Layout.fillWidth: true; label: "Bluetooth"; detail: Bluetooth.defaultAdapter ? (Bluetooth.defaultAdapter.enabled ? "On" : "Off") : "No adapter"; symbol: "bluetooth"; hasMenu: true; toggled: Bluetooth.defaultAdapter?.enabled ?? false; enabled: !!Bluetooth.defaultAdapter; onActivated: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; onOpenMenu: Quickshell.execDetached(["blueman-manager"]) }
            ControlTile { Layout.fillWidth: true; label: "Sound"; detail: Pipewire.defaultAudioSink?.description || "No output"; symbol: Pipewire.defaultAudioSink?.audio?.muted ? "volume_off" : "volume_up"; hasMenu: true; toggled: !!Pipewire.defaultAudioSink?.audio && !Pipewire.defaultAudioSink.audio.muted; enabled: !!Pipewire.defaultAudioSink?.audio; onActivated: Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted; onOpenMenu: Quickshell.execDetached(["pavucontrol"]) }
            ControlTile { Layout.fillWidth: true; label: "Do not disturb"; detail: Config.options.notifications.dnd ? "On" : "Off"; symbol: "notifications_paused"; toggled: Config.options.notifications.dnd; onActivated: Config.options.notifications.dnd = !Config.options.notifications.dnd }
            ControlTile { Layout.fillWidth: true; label: "Dark mode"; detail: Config.options.appearance.dark ? "On" : "Off"; symbol: "dark_mode"; toggled: Config.options.appearance.dark; onActivated: Config.options.appearance.dark = !Config.options.appearance.dark }
            ControlTile { Layout.fillWidth: true; label: "Battery saver"; detail: Controls.state.powerProfile || "Unavailable"; symbol: "energy_savings_leaf"; toggled: Controls.state.powerProfile === "power-saver"; enabled: Controls.state.powerProfile !== "" && !Controls.busy; onActivated: Controls.set("profile", toggled ? "balanced" : "power-saver") }
        }
        StyledText { visible: Controls.error !== ""; text: Controls.error; Layout.fillWidth: true; wrapMode: Text.Wrap; color: Appearance.m3colors.m3error; font.pixelSize: 12 }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 180; Layout.minimumHeight: 130
            color: Appearance.colors.colLayer1; radius: 20
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 4
                RowLayout {
                    StyledText { text: "Notifications"; Layout.fillWidth: true; font.pixelSize: 14; opacity: 0.8 }
                    ActionButton { symbol: "clear_all"; Accessible.name: "Clear notifications"; enabled: root.notices.length > 0; onClicked: root.clearNotices() }
                }
                StyledText { visible: root.notices.length === 0; text: "You're all caught up"; Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; opacity: 0.5; font.pixelSize: 13 }
                ListView {
                    visible: root.notices.length > 0; Layout.fillHeight: true; Layout.fillWidth: true; clip: true; spacing: 8
                    model: root.notices
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; implicitHeight: content.implicitHeight + 16; radius: 14; color: Appearance.colors.colLayer2
                        ColumnLayout {
                            id: content; anchors.fill: parent; anchors.margins: 8; spacing: 4
                            RowLayout {
                                StyledText { text: modelData?.summary || ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true; font.weight: Font.DemiBold; font.pixelSize: 13 }
                                ActionButton { symbol: "close"; Accessible.name: "Dismiss notification"; onClicked: modelData?.dismiss() }
                            }
                            StyledText { text: modelData?.body || ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: 12; opacity: 0.7 }
                            Flow { Layout.fillWidth: true; Repeater { model: modelData?.actions || []; ActionButton { required property var modelData; label: modelData.text; onClicked: modelData.invoke() } } }
                        }
                    }
                }
            }
        }
        MediaCard { Layout.fillWidth: true; visible: Config.options.controls.showMedia && !!Media.player }
        ProductivityGroup {
            objectName: "sidebarWidgets"
            Layout.fillWidth: true; visible: Config.options.controls.showCalendar
            onHeightChanged: if (!collapsed) Qt.callLater(() => { if (root.contentItem) root.contentItem.contentY = Math.max(0, root.contentHeight - root.availableHeight); });
        }
        StyledText { Layout.fillWidth: true; text: Qt.formatDateTime(new Date(), "dddd, d MMMM") + (UPower.displayDevice.isLaptopBattery ? "  ·  " + Math.round(UPower.displayDevice.percentage * 100) + "%" : ""); horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12; opacity: 0.65 }
    }
}
