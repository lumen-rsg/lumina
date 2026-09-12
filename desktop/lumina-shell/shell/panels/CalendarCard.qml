import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    property bool compact: false
    signal expandRequested()
    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()
    function step(delta) { const next = new Date(year, month + delta, 1); year = next.getFullYear(); month = next.getMonth(); }
    implicitHeight: body.implicitHeight + 16
    color: Appearance.colors.colLayer1; radius: 20
    ColumnLayout {
        id: body
        anchors.fill: parent; anchors.margins: 8; spacing: 2
        RowLayout {
            ActionButton { symbol: "chevron_left"; Accessible.name: "Previous month"; onClicked: root.step(-1) }
            StyledText { Layout.fillWidth: true; text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy"); horizontalAlignment: Text.AlignHCenter }
            ActionButton { label: root.compact ? "Calendar" : "Today"; onClicked: { if (root.compact) { root.expandRequested(); return; } root.month = root.today.getMonth(); root.year = root.today.getFullYear(); } }
            ActionButton { symbol: "chevron_right"; Accessible.name: "Next month"; onClicked: root.step(1) }
        }
        GridLayout {
            visible: !root.compact
            columns: 7; rowSpacing: 1; columnSpacing: 1; Layout.fillWidth: true
            Repeater { model: ["M", "T", "W", "T", "F", "S", "S"]; StyledText { required property string modelData; text: modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; opacity: 0.45; font.pixelSize: 11 } }
            Repeater {
                model: Math.ceil((root.offset + root.days) / 7) * 7
                Rectangle {
                    required property int index
                    readonly property int day: index - root.offset + 1
                    readonly property bool valid: day > 0 && day <= root.days
                    readonly property bool current: valid && day === root.today.getDate() && root.month === root.today.getMonth() && root.year === root.today.getFullYear()
                    Layout.fillWidth: true; implicitHeight: 25; radius: 13
                    color: current ? Appearance.colors.colPrimary : "transparent"
                    StyledText { anchors.centerIn: parent; text: parent.valid ? parent.day : ""; font.pixelSize: 12; color: parent.current ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1 }
                }
            }
        }
    }
}
