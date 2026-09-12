pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var state: ({wifiAvailable: false, wifiEnabled: false, connection: "Checking network…", brightness: null, powerProfile: "", uptime: ""})
    property string error: ""
    property var pending: null
    readonly property bool busy: request.running
    readonly property string helper: Quickshell.env("LUMINA_CONTROLS_HELPER") || "/usr/libexec/lumina-controls"
    function refresh() { if (!request.running) { request.command = [helper, "status"]; request.running = true; } }
    function set(action, value) {
        if (request.running) { pending = [action, value]; return; }
        error = "";
        request.command = [helper, action, String(value)];
        request.running = true;
    }
    Process {
        id: request
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (result.state) root.state = result.state;
                    if (!result.ok) root.error = result.error || "Control could not be changed";
                } catch (e) { root.error = "Could not read system controls"; }
            }
        }
        onExited: (code, status) => { if (code !== 0 && !root.error) root.error = "System control service is unavailable"; if (root.pending) drain.restart(); }
    }
    Timer { id: drain; interval: 1; onTriggered: { const next = root.pending; root.pending = null; if (next) root.set(next[0], next[1]); } }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
