//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import "panels"
import "services"
import "modules/common"

ShellRoot {
    id: root
    property int step: 0
    function check(ok, message) { if (!ok) { console.error(message); Qt.exit(1); } }
    function find(item, name) { if (item.objectName === name) return item; for (const child of item.children || []) { const result = find(child, name); if (result) return result; } return null; }
    PanelWindow { implicitWidth: 454; implicitHeight: 550; color: "transparent"; ControlCenter { id: controls; anchors.fill: parent } }
    Timer {
        interval: 300; running: true; repeat: true
        onTriggered: {
            if (root.step === 0) Config.options.controls.widgetsCollapsed = true;
            if (root.step === 1) root.find(controls, "widgetTab2").clicked();
            if (root.step === 2) {
                const group = root.find(controls, "sidebarWidgets");
                root.check(!group.collapsed && group.selectedTab === 2, "Compact Timer button failed");
                root.check(controls.contentItem.contentY > 0, "Expanded group did not scroll into view");
                const timer = root.find(group, "timerToggle"); root.check(!!timer, "Expanded timer not loaded");
                const position = timer.mapToItem(controls, 0, 0);
                root.check(position.y >= 0 && position.y + timer.height <= controls.height, "Timer controls outside viewport: " + JSON.stringify({y: position.y, height: timer.height, viewport: controls.height, content: controls.contentHeight, scroll: controls.contentItem.contentY}));
                Quickshell.execDetached(["grim", Quickshell.env("LUMINA_QA_ARTIFACTS") + "/sidebar-expanded.png"]);
            }
            if (root.step === 4) { console.warn("SIDEBAR_FIXTURE_PASS"); Qt.quit(); }
            root.step++;
        }
    }
}
