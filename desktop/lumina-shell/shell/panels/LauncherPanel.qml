import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    signal launched()
    spacing: 12
    StyledText { text: "Applications"; font.pixelSize: 24 }
    InputField { id: search; Layout.fillWidth: true; placeholderText: "Search your apps"; Accessible.name: "Search applications"; Component.onCompleted: forceActiveFocus() }
    ListView {
        id: apps
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: DesktopEntries.applications.values.filter(app => !app.noDisplay && app.name.toLowerCase().includes(search.text.toLowerCase())).sort((a,b) => a.name.localeCompare(b.name))
        delegate: ActionButton {
            required property var modelData
            width: apps.width
            label: modelData.name
            onClicked: { modelData.execute(); root.launched(); }
        }
    }
}
