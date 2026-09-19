//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import Quickshell.Io
import "spatial"
import "panels"
import "services"
import "modules/common"

ShellRoot {
    id: root
    property int step: 0
    property int pointId: 0
    property int targetWindow: 0
    property var overlay: null
    property var plot: null
    function check(ok, message) { if (!ok) { console.error(message); Qt.exit(1); } }
    function find(item, name, seen) {
        if (!item || seen.indexOf(item) >= 0) return null;
        seen.push(item);
        if (item.objectName === name) return item;
        let children = [];
        for (const child of item.data || []) children.push(child);
        for (const child of item.children || []) children.push(child);
        if (item.contentItem) children.push(item.contentItem);
        for (const child of children) { const result = find(child, name, seen); if (result) return result; }
        return null;
    }
    Overview { id: overview; opened: true; output: Quickshell.screens[0] }
    Cheatsheet { id: guide; opened: false }
    SpatialFeedback { screen: Quickshell.screens[0] }
    SettingsWindow { id: settings }
    Process { id: capture }
    function shot(name) { capture.exec(["grim", Quickshell.env("LUMINA_QA_ARTIFACTS") + "/" + name + ".png"]); }
    Timer {
        interval: 150; running: true; repeat: true
        onTriggered: {
            if (Quickshell.env("LUMINA_SPATIAL_RELOAD") === "1") {
                if (root.step++ < 3) return;
                root.check(Config.options.appearance.theme === "sandy", "Palette choice did not persist");
                root.check(!Appearance.m3colors.darkmode && String(Appearance.m3colors.m3background) === "#f5e9d4", "Sandy did not restore across processes");
                console.warn("SPATIAL_RELOAD_PASS"); Qt.quit(); return;
            }
            if (root.step === 0) {
                if (!Chroma.connected || !Chroma.windows.length) return;
                root.targetWindow = Chroma.windows[0].id;
                root.overlay = root.find(overview, "canvasOverlay", []);
                root.plot = root.find(overview, "canvasPlot", []);
                root.check(!!root.overlay && !!root.plot, "Spatial overview failed to instantiate");
                Shortcuts.refreshBindings();
                Chroma.action("move_view -1200 800");
            }
            if (root.step === 2) {
                root.check(Math.abs(Chroma.viewportX + 1200) < 1, "Canvas movement did not reach compositor");
                Chroma.action("mark_teleport");
            }
            if (root.step === 4) {
                root.check(Chroma.teleports.length === 1, "Save point failed");
                root.pointId = Chroma.teleports[0].id;
                root.overlay.selectedTeleportId = root.pointId;
                Chroma.action("rename_teleport " + root.pointId + " Design desk");
            }
            if (root.step === 6) {
                root.check(Chroma.teleports[0].name === "Design desk", "Rename point failed");
                Chroma.action("bring_window " + root.targetWindow);
                root.check(Shortcuts.bindings.length > 10 && Shortcuts.error === "", "Effective shortcut helper failed");
                root.check(Shortcuts.sections[3].items.some(i => i.action === "Canvas overview"), "Spawn shortcut argument was not decoded");
                root.check(!Shortcuts.keys("zoom_reset").includes("Unbound"), "Shortcut lookup failed");
            }
            if (root.step === 8) {
                Chroma.action("move_view 0 0");
                root.overlay.selectedTeleportId = 0;
            }
            if (root.step === 10) Chroma.action("jump_teleport " + root.pointId);
            if (root.step === 12) {
                if (Math.abs(Chroma.viewportX + 1200) >= 1) return; // Wait for the compositor animation.
                const scale = root.plot.mapScale;
                root.check(scale > 0 && Number.isFinite(scale), "Map scale is invalid");
                root.check(Math.abs(root.plot.canvasX(root.plot.mapX(-1200)) + 1200) < 0.001, "Map X coordinate inverse failed");
                root.check(Math.abs(root.plot.canvasY(root.plot.mapY(800)) - 800) < 0.001, "Map Y coordinate inverse failed");
                const search = root.find(overview, "windowSearch", []);
                search.text = "no-such-lumina-window";
                root.check(root.overlay.filteredWindows.length === 0, "Window search did not filter");
                search.text = Chroma.windows[0].app_id;
                root.check(root.overlay.filteredWindows.length > 0, "Application search failed");
                search.text = "";
                Appearance.selectTheme("forest");
            }
            if (root.step === 14) {
                root.check(String(Appearance.m3colors.m3background) === "#101713", "Forest background did not apply");
                root.check(String(Appearance.m3colors.m3primary) === "#a8c7a0", "Forest accent did not apply");
                root.shot("overview-forest");
            }
            if (root.step === 16) { Appearance.selectTheme("sandy"); }
            if (root.step === 18) {
                root.check(!Appearance.m3colors.darkmode && String(Appearance.m3colors.m3background) === "#f5e9d4", "Sandy palette did not apply");
                root.shot("overview-sandy");
            }
            if (root.step === 20) { overview.opened = false; settings.open(0); }
            if (root.step === 22) root.shot("settings-sandy");
            if (root.step === 24) { settings.visible = false; guide.opened = true; }
            if (root.step === 26) root.shot("guide-sandy");
            if (root.step === 28) {
                guide.opened = false;
                Chroma.action("focus_window 999999");
            }
            if (root.step === 30) {
                root.check(Chroma.feedback?.kind === "warning", "Rejected action has no warning popup");
                root.shot("warning-sandy");
                Chroma.action("remove_teleport " + root.pointId);
            }
            if (root.step === 32) {
                root.check(Chroma.teleports.length === 0, "Remove point failed");
                Chroma.action("reset_view");
            }
            // A repeated state snapshot must not keep a feedback toast alive.
            if (root.step >= 34 && root.step <= 48) {
                Chroma.consume(JSON.stringify({type: "state", version: 2, viewport: {x: 0, y: 0, width: 1280, height: 800, zoom: 1}, windows: [], teleports: [], feedback: {serial: 1000000, kind: "zoom", message: "Zoom 100%"}}));
            }
            if (root.step === 49) {
                root.check(Chroma.feedback === null, "Repeated serial restarted feedback timeout");
                root.check(root.overlay.contentWidth > 0 && root.plot.mapScale > 0, "Empty canvas has invalid bounds");
                Chroma.consume("invalid-json");
                root.check(Chroma.feedback?.kind === "warning", "Malformed response has no warning");
            }
            if (root.step === 52) { console.warn("SPATIAL_FIXTURE_PASS"); Qt.quit(); }
            root.step++;
        }
    }
    Timer { interval: 20000; running: true; onTriggered: { console.error("Spatial fixture timed out at step " + root.step); Qt.exit(2); } }
}
