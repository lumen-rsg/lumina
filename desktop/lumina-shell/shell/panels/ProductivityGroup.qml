// Adapted from the pinned ii/sidebarRight/BottomWidgetGroup.qml.
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    property bool forceExpanded: false
    readonly property bool collapsed: !forceExpanded && Config.options.controls.widgetsCollapsed
    property int selectedTab: Config.options.controls.widgetTab
    readonly property var tabs: [{name: "Calendar", icon: "calendar_month"}, {name: "To Do", icon: "done_outline"}, {name: "Timer", icon: "schedule"}]
    implicitHeight: collapsed ? 52 : 324
    color: Appearance.colors.colLayer1; radius: 20; clip: true
    function selectTab(index) { Config.options.controls.widgetTab = index; Config.options.controls.widgetsCollapsed = false; }
    RowLayout {
        anchors.fill: parent; anchors.margins: 6; visible: root.collapsed
        ActionButton { symbol: "keyboard_arrow_up"; Accessible.name: "Expand sidebar widgets"; onClicked: Config.options.controls.widgetsCollapsed = false }
        StyledText { Layout.fillWidth: true; text: Productivity.remainingTasks + " tasks"; font.pixelSize: 12; opacity: 0.7 }
        Repeater { model: root.tabs; ActionButton { required property int index; required property var modelData; objectName: "widgetTab" + index; symbol: modelData.icon; Accessible.name: modelData.name; onClicked: root.selectTab(index) } }
    }
    RowLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 10; visible: !root.collapsed
        ColumnLayout {
            Layout.preferredWidth: 70; Layout.fillHeight: true
            ActionButton { visible: !root.forceExpanded; symbol: "keyboard_arrow_down"; Accessible.name: "Collapse sidebar widgets"; onClicked: Config.options.controls.widgetsCollapsed = true }
            Item { Layout.fillHeight: true }
            NavigationRailTabArray {
                currentIndex: root.selectedTab; expanded: false
                Repeater { model: root.tabs
                    NavigationRailButton { required property int index; required property var modelData; baseSize: 48; expanded: false; toggled: root.selectedTab === index; showToggledHighlight: false; buttonText: modelData.name; buttonIcon: modelData.icon; onClicked: root.selectTab(index) }
                }
            }
            Item { Layout.fillHeight: true }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            Loader {
                Layout.fillWidth: true; Layout.fillHeight: true
                active: !root.collapsed
                sourceComponent: root.selectedTab === 1 ? todo : root.selectedTab === 2 ? timer : calendar
            }
            StyledText { visible: Productivity.error !== ""; text: Productivity.error; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12; color: Appearance.m3colors.m3error }
        }
    }
    Component { id: calendar; CalendarCard { color: "transparent" } }
    Component { id: todo; TodoWidget {} }
    Component { id: timer; TimerWidget {} }
}
