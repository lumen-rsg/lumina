//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import "panels"
import "services"

ShellRoot {
    id: root
    property int step: 0
    property int attempts: 0
    function check(ok, message) { if (!ok) { console.error(message); Qt.exit(1); } }
    function find(item, name) { if (item.objectName === name) return item; for (const child of item.children || []) { const result = find(child, name); if (result) return result; } return null; }
    PanelWindow { implicitWidth: 460; implicitHeight: 170; color: "transparent"; MediaCard { id: card; anchors.fill: parent } }
    Timer {
        interval: 350; running: true; repeat: true
        onTriggered: {
            if (root.step === 0 && !Media.player) { root.check(root.attempts++ < 30, "MPRIS player was not discovered"); return; }
            if (root.step === 0) { root.check(Media.player.trackTitle === "First track", "Metadata missing"); root.find(card, "mediaToggle").clicked(); }
            if (root.step === 1) { root.check(Media.player.isPlaying, "Play did not reach player"); Quickshell.execDetached(["grim", Quickshell.env("LUMINA_QA_ARTIFACTS") + "/media.png"]); root.find(card, "mediaToggle").clicked(); root.find(card, "mediaNext").clicked(); }
            if (root.step === 2) {
                root.check(!Media.player.isPlaying, "Pause failed");
                root.check(Media.player.trackTitle === "Next track", "Next/metadata signal failed");
                const slider = root.find(card, "mediaSeek"); root.check(slider.enabled, "Seek disabled"); slider.value = 0.5;

            }
            if (root.step === 3) { root.find(card, "mediaSeek").moved(); root.find(card, "mediaPrevious").clicked(); }
            if (root.step === 4) { root.check(Media.player.trackTitle === "Previous track", "Previous failed"); root.check(!root.find(card, "mediaNext").enabled, "Capabilities not reflected"); Media.player.quit(); }
            if (root.step === 6) { root.check(!Media.player && !root.find(card, "mediaToggle").enabled, "Removed player retained active controls"); console.warn("MEDIA_FIXTURE_PASS"); Qt.quit(); }
            root.step++;
        }
    }
}
