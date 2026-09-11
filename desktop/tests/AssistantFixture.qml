import QtQuick
import Quickshell
import "services"

ShellRoot {
    id: root
    property int step: 0
    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            if (Assistant.error !== "") { console.error("FIXTURE FAIL: " + Assistant.error); Qt.exit(1); }
            if (root.step === 0 && !Assistant.working) {
                Assistant.configure("openai-compatible", "fixture-model", Quickshell.env("LUMINA_QA_AI_ENDPOINT"), "fixture-key");
                root.step = 1;
            } else if (root.step === 1 && Assistant.configured) {
                Assistant.send("Hello from QML");
                root.step = 2;
            } else if (root.step === 2 && Assistant.messages.length === 2) {
                if (Assistant.messages[1].content !== "Fixture response") { Qt.exit(2); return; }
                console.warn("ASSISTANT_FIXTURE_PASS");
                Qt.exit(0);
            }
        }
    }
    Timer { interval: 10000; running: true; onTriggered: { console.error("FIXTURE TIMEOUT"); Qt.exit(3); } }
}
