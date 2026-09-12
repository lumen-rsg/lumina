//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import Quickshell.Io
import "panels"
import "modules/common"

ShellRoot {
    id: root
    property int step: 0
    function check(condition, message) { if (!condition) { console.error(message); Qt.exit(1); } }
    function button(item, text) {
        if (item.text === text && item.clicked && item.checked !== undefined) return item;
        for (const child of item.children || []) { const found = button(child, text); if (found) return found; }
        return null;
    }
    SettingsWindow { id: settings; Component.onCompleted: open() }
    Timer {
        interval: 250; repeat: true; running: true
        onTriggered: {
            if (Quickshell.env("LUMINA_SETTINGS_VERIFY_RELOAD") === "1") {
                if (root.step++ < 2) return;
                root.check(Config.options.notifications.dnd, "DND was not restored");
                root.check(!Config.options.appearance.dark, "Theme was not restored");
                root.check(!Config.options.bar.showAssistant, "Bar preference was not restored");
                console.warn("SETTINGS_RELOAD_PASS"); Qt.quit(); return;
            }
            if (root.step < 8) { settings.currentPage = root.step; root.check(settings.visible, "Settings disappeared"); }
            if (root.step === 8) {
                settings.currentPage = 5;
                const dnd = root.button(settings.contentItem, "Do not disturb");
                root.check(!!dnd, "Notification control missing");
                dnd.clicked();
                root.check(Config.options.notifications.dnd, "DND control did not update Config");
                Config.options.appearance.dark = false;
                Config.options.bar.showAssistant = false;
            }
            if (root.step === 10) {
                root.check(!Appearance.m3colors.darkmode, "Light palette did not update");
                root.check(Appearance.colors.colLayer1.a > 0.9, "Content cards are transparent with transparency disabled");
                const dnd = root.button(settings.contentItem, "Do not disturb");
                root.check(dnd.checked, "Control binding was lost");
                Config.options.notifications.dnd = false;
                root.check(!dnd.checked, "External config change did not update switch");
                dnd.clicked();
                settings.width = 700; settings.height = 600;
            }
            if (root.step === 16) { console.warn("SETTINGS_FIXTURE_PASS"); Qt.quit(); }
            root.step++;
        }
    }
}
