pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string socketPath: Quickshell.env("CHROMA_CONTROL_SOCKET") || (Quickshell.env("XDG_RUNTIME_DIR") + "/chroma/" + Quickshell.env("WAYLAND_DISPLAY") + "/control.sock")
    property var state: ({windows: [], teleports: [], viewport: {zoom: 1}, focused: null})
    property string error: ""
    readonly property bool connected: socket.connected
    function action(command) {
        if (!socket.connected || /[\r\n]/.test(command)) return;
        socket.write("action " + command + "\n");
        socket.flush();
    }
    Socket {
        id: socket
        path: root.socketPath
        connected: true
        onConnectedChanged: {
            if (connected) { write("watch\n"); flush(); root.error = ""; }
            else reconnect.restart();
        }
        parser: SplitParser {
            onRead: data => {
                try {
                    const message = JSON.parse(data);
                    if (message.type === "state" && message.version === 2) root.state = message;
                    else if (message.type === "state") root.error = "Unsupported Chroma state version";
                    else if (message.ok === false) root.error = message.message || "Chroma action failed";
                } catch (e) { root.error = "Invalid Chroma response"; }
            }
        }
    }
    Timer { id: reconnect; interval: 1000; onTriggered: socket.connected = true }
}
