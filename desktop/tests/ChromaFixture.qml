import QtQuick
import Quickshell
import "services"

ShellRoot {
    id: root
    property int step: 0
    property real initialZoom: 0
    property int windowId: -1
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (Chroma.error) { console.error(Chroma.error); Qt.exit(1); }
            if (root.step === 0 && Chroma.connected && Chroma.state.windows.length === 1) {
                root.initialZoom = Chroma.state.viewport.zoom;
                root.windowId = Chroma.state.windows[0].id;
                Chroma.action("zoom_in");
                root.step = 1;
            } else if (root.step === 1 && Chroma.state.viewport.zoom > root.initialZoom) {
                Chroma.action("close_window " + root.windowId);
                root.step = 2;
            } else if (root.step === 2 && Chroma.state.windows.length === 0) {
                console.warn("CHROMA_ACTION_FIXTURE_PASS");
                Qt.exit(0);
            }
        }
    }
    Timer { interval: 15000; running: true; onTriggered: { console.error("Chroma action test timed out"); Qt.exit(2); } }
}
