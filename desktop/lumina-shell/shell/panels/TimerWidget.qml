// Adapted from ii/sidebarRight/pomodoro: circular timer and stopwatch laps.
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root
    property bool stopwatch: false
    enabled: Productivity.ready
    spacing: 6
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        ActionButton { label: "Pomodoro"; toggled: !root.stopwatch; onClicked: root.stopwatch = false }
        ActionButton { label: "Stopwatch"; toggled: root.stopwatch; onClicked: root.stopwatch = true }
    }
    Item { Layout.fillHeight: true; visible: !root.stopwatch }
    CircularProgress {
        visible: !root.stopwatch; Layout.alignment: Qt.AlignHCenter
        implicitSize: Math.max(100, Math.min(174, root.height - 108)); lineWidth: 7
        value: Productivity.secondsLeft / Productivity.duration(Productivity.data.phase)
        enableAnimation: !Config.options.appearance.reducedMotion
        Column {
            anchors.centerIn: parent; spacing: 4
            StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Productivity.format(Productivity.secondsLeft); font.pixelSize: 30 }
            StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Productivity.data.phase; font.capitalization: Font.Capitalize; opacity: 0.7; font.pixelSize: 13 }
            StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "Session " + (Productivity.data.cycles + 1); opacity: 0.5; font.pixelSize: 11 }
        }
    }
    StyledText { visible: root.stopwatch; Layout.alignment: Qt.AlignHCenter; text: Productivity.format(Productivity.stopwatchMs / 1000) + "." + Math.floor(Productivity.stopwatchMs % 1000 / 100); font.pixelSize: 36 }
    ListView {
        visible: root.stopwatch; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
        model: Productivity.data.laps.slice().reverse()
        delegate: StyledText { required property int index; required property double modelData; text: "Lap " + (Productivity.data.laps.length - index) + "     " + Productivity.format(modelData / 1000) + "." + Math.floor(modelData % 1000 / 100); font.pixelSize: 14 }
        StyledText { anchors.centerIn: parent; visible: Productivity.data.laps.length === 0; text: "Record a lap while running"; font.pixelSize: 12; opacity: 0.5 }
    }
    Item { Layout.fillHeight: true; visible: !root.stopwatch }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        ActionButton { objectName: "timerToggle"; label: (root.stopwatch ? Productivity.data.started > 0 : Productivity.data.deadline > 0) ? "Pause" : "Start"; symbol: (root.stopwatch ? Productivity.data.started > 0 : Productivity.data.deadline > 0) ? "pause" : "play_arrow"; onClicked: root.stopwatch ? Productivity.toggleStopwatch() : Productivity.toggleFocus() }
        ActionButton { visible: root.stopwatch && Productivity.data.started > 0; label: "Lap"; onClicked: Productivity.lap() }
        ActionButton { label: "Reset"; symbol: "restart_alt"; onClicked: root.stopwatch ? Productivity.resetStopwatch() : Productivity.resetFocus() }
    }
}
