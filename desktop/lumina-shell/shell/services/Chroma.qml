pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string socketPath: Quickshell.env("CHROMA_CONTROL_SOCKET") || (Quickshell.env("XDG_RUNTIME_DIR") + "/chroma/" + Quickshell.env("WAYLAND_DISPLAY") + "/control.sock")
    property var state: ({windows: [], teleports: [], viewport: {zoom: 1}, focused: null})
    property string error: ""
    readonly property var windows: state.windows || []
    readonly property var teleports: state.teleports || []
    readonly property real viewportX: state.viewport?.x ?? 0
    readonly property real viewportY: state.viewport?.y ?? 0
    readonly property real viewportWidth: state.viewport?.width ?? 0
    readonly property real viewportHeight: state.viewport?.height ?? 0
    readonly property real zoom: state.viewport?.zoom ?? 1
    readonly property bool windowsTruncated: state.windows_truncated ?? false
    readonly property bool canRestoreArrangement: state.can_restore_arrangement ?? false
    property var feedback: null
    property double feedbackSerial: -1
    function warn(message) {
        error = message;
        feedback = {kind: "warning", message: message};
        feedbackTimer.restart();
    }
    function consume(data) {
        try {
            const message = JSON.parse(data);
            if (message.type === "state" && message.version === 2) {
                state = message;
                if (message.feedback && message.feedback.serial !== feedbackSerial) {
                    feedbackSerial = message.feedback.serial;
                    feedback = message.feedback;
                    feedbackTimer.restart();
                }
            } else if (message.type === "state") warn("Unsupported Chroma state version");
            else if (message.ok === false) warn(message.message || "Chroma action failed");
            else if (message.type === "result" && message.ok) error = "";
        } catch (e) { warn("Invalid Chroma response"); }
    }
    Timer { id: feedbackTimer; interval: root.feedback?.kind === "warning" ? 5000 : 1800; onTriggered: root.feedback = null }
    readonly property bool connected: socket.connected
    function action(command) {
        if (!socket.connected) { warn("Compositor control is unavailable"); return; }
        if (!command || /[\r\n]/.test(command)) { warn("Invalid Chroma action"); return; }
        socket.write("action " + command + "\n");
        socket.flush();
    }
    Socket {
        id: socket
        path: root.socketPath
        connected: true
        onConnectedChanged: {
            if (connected) { write("watch\n"); flush(); root.error = ""; root.feedbackSerial = -1; }
            else { root.warn("Compositor control disconnected"); reconnect.restart(); }
        }
        parser: SplitParser {
            onRead: data => root.consume(data)
        }
    }
    Timer { id: reconnect; interval: 1000; onTriggered: socket.connected = true }
}
