pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var messages: []
    property bool busy: false
    property bool ready: false
    readonly property bool working: !ready || worker.running
    property string error: ""
    property string provider: ""
    property string model: ""
    property string endpoint: ""
    property bool configured: false
    property string pending: ""
    function configure(provider, model, endpoint, key) {
        if (working) return;
        root.pending = JSON.stringify({operation: "configure", provider: provider, model: model, endpoint: endpoint, key: key});
        worker.running = true;
    }
    function send(text) {
        if (working || busy || !configured || !text.trim()) return;
        error = "";
        messages = messages.concat([{role: "user", content: text.trim()}]);
        root.pending = JSON.stringify({operation: "chat", messages: messages});
        busy = true;
        worker.running = true;
    }
    function cancel() { worker.running = false; busy = false; }
    function clear() { cancel(); messages = []; error = ""; }
    function refresh() {
        root.pending = JSON.stringify({operation: "status"}); worker.running = true;
    }
    Component.onCompleted: refresh()
    Process {
        id: worker
        command: [Quickshell.env("LUMINA_ASSISTANT_HELPER") || "/usr/libexec/lumina-assistant"]
        stdinEnabled: true
        onStarted: { write(root.pending + "\n"); root.pending = ""; stdinEnabled = false; }
        onRunningChanged: if (!running) stdinEnabled = true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return;
                try {
                    const result = JSON.parse(text);
                    if (result.error) root.error = result.error;
                    else if (result.content !== undefined) root.messages = root.messages.concat([{role: "assistant", content: result.content}]);
                    else { root.provider = result.provider || ""; root.model = result.model || ""; root.endpoint = result.endpoint || ""; root.configured = result.configured || false; }
                } catch (e) { root.error = "The assistant returned an invalid response."; }
            }
        }
        onExited: (code, status) => { root.ready = true; root.busy = false; if (code && !root.error) root.error = "Assistant request failed."; }
    }
}
