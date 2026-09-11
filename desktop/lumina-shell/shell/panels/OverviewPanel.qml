import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    spacing: 12
    StyledText { text: "Your canvas"; font.pixelSize: 24 }
    StyledText { text: "Windows and saved places"; opacity: 0.6 }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        ActionButton { label: "−"; onClicked: Chroma.action("zoom_out") }
        ActionButton { label: Math.round((Chroma.state.viewport?.zoom ?? 1) * 100) + "%"; onClicked: Chroma.action("zoom_reset") }
        ActionButton { label: "+"; onClicked: Chroma.action("zoom_in") }
        ActionButton { label: "Home"; symbol: "center_focus_strong"; onClicked: Chroma.action("reset_view") }
        ActionButton { label: "Grid"; onClicked: Chroma.action("tile_grid") }
        ActionButton { label: "Columns"; onClicked: Chroma.action("tile_columns") }
        ActionButton { label: "Restore"; enabled: Chroma.state.can_restore_arrangement ?? false; onClicked: Chroma.action("restore_layout") }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: Chroma.state.teleports || []
            ActionButton {
                required property var modelData
                label: modelData.name || "Point " + modelData.id
                symbol: "place"
                toggled: modelData.active
                onClicked: Chroma.action("jump_teleport " + modelData.id)
            }
        }
    }
    ListView {
        id: windows
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: Chroma.state.windows || []
        delegate: Rectangle {
            required property var modelData
            width: windows.width
            height: 88
            radius: 18
            color: modelData.focused ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
            RowLayout {
                anchors.fill: parent; anchors.margins: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    StyledText { text: modelData.title || modelData.app_id; Layout.fillWidth: true; elide: Text.ElideRight }
                    StyledText { text: modelData.app_id; opacity: 0.6; font.pixelSize: 12 }
                }
                ActionButton { label: "Go"; onClicked: Chroma.action("focus_window " + modelData.id) }
                ActionButton { label: "Bring"; onClicked: Chroma.action("bring_window " + modelData.id) }
                ActionButton { symbol: "close"; label: ""; Accessible.name: "Close window"; onClicked: Chroma.action("close_window " + modelData.id) }
            }
        }
    }
    StyledText { visible: !Chroma.connected || Chroma.error !== ""; text: Chroma.error || "Connecting to Chroma…"; color: Appearance.m3colors.m3error }
}
