// Adapted from ii/sidebarRight/todo/TodoWidget.qml and TaskList.qml.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root
    property bool showDone: false
    property var deletedTask: null
    spacing: 8
    enabled: Productivity.ready
    RowLayout {
        Layout.fillWidth: true
        ActionButton { label: "To do"; toggled: !root.showDone; onClicked: root.showDone = false }
        ActionButton { label: "Done"; toggled: root.showDone; onClicked: root.showDone = true }
        Item { Layout.fillWidth: true }
    }
    RowLayout {
        Layout.fillWidth: true
        InputField { id: input; objectName: "taskInput"; Layout.fillWidth: true; placeholderText: "Add a task"; maximumLength: 2000; onAccepted: add.clicked() }
        ActionButton { id: add; objectName: "taskAdd"; symbol: "add"; Accessible.name: "Add task"; enabled: input.text.trim().length > 0; onClicked: if (Productivity.addTask(input.text)) { input.clear(); root.showDone = false; } }
    }
    ListView {
        id: list
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
        model: Productivity.tasks.filter(t => t.done === root.showDone)
        ScrollBar.vertical: StyledScrollBar {}
        delegate: Rectangle {
            id: task
            required property var modelData
            width: ListView.view.width; implicitHeight: Math.max(52, row.implicitHeight + 12)
            radius: 14; color: Appearance.colors.colLayer2
            RowLayout {
                id: row
                anchors.fill: parent; anchors.margins: 6
                ActionButton { symbol: task.modelData.done ? "check_circle" : "radio_button_unchecked"; Accessible.name: (task.modelData.done ? "Reopen " : "Complete ") + task.modelData.text; onClicked: Productivity.toggleTask(task.modelData.id) }
                StyledText { Layout.fillWidth: true; text: task.modelData.text; textFormat: Text.PlainText; wrapMode: Text.Wrap; font.pixelSize: 13; font.strikeout: task.modelData.done }
                ActionButton { symbol: "delete"; Accessible.name: "Delete task"; onClicked: { root.deletedTask = task.modelData; Productivity.deleteTask(task.modelData.id); } }
            }
        }
        StyledText { anchors.centerIn: parent; visible: list.count === 0; text: root.showDone ? "Finished tasks will go here" : "Nothing here!"; opacity: 0.6; font.pixelSize: 13 }
    }
    ActionButton { visible: root.deletedTask !== null; label: "Undo delete"; symbol: "undo"; onClicked: { Productivity.restoreTask(root.deletedTask); root.showDone = root.deletedTask.done; root.deletedTask = null; } }
}
