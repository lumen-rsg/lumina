import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root
    spacing: 12
    property bool editing: !Assistant.configured
    RowLayout {
        Layout.fillWidth: true
        StyledText { text: "Lumina Assistant"; font.pixelSize: 24; Layout.fillWidth: true }
        ActionButton { symbol: "settings"; label: "Provider"; enabled: !Assistant.busy; onClicked: root.editing = !root.editing }
    }
    StyledText {
        Layout.fillWidth: true
        text: Assistant.configured ? Assistant.provider + " · " + Assistant.model : "Choose a provider to get started"
        opacity: 0.65
        wrapMode: Text.Wrap
    }
    ScrollView {
        id: providerScroll
        visible: root.editing
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(providerSettings.implicitHeight, root.height * 0.58)
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: providerSettings
            width: providerScroll.availableWidth
            ComboBox {
                id: provider
                palette.button: Appearance.colors.colLayer2
                palette.buttonText: Appearance.m3colors.m3onSurface
                palette.base: Appearance.colors.colLayer1
                palette.text: Appearance.m3colors.m3onSurface
                palette.highlight: Appearance.m3colors.m3primary
                palette.highlightedText: Appearance.m3colors.m3onPrimary
                background: Rectangle { radius: 12; color: Appearance.colors.colLayer2 }
                Layout.fillWidth: true
                model: ["Choose provider", "OpenAI-compatible", "Anthropic", "Gemini", "Ollama"]
                currentIndex: Math.max(0, ["", "openai-compatible", "anthropic", "gemini", "ollama"].indexOf(Assistant.provider))
            }
            InputField { id: modelName; Layout.fillWidth: true; placeholderText: "Model ID from your provider"; text: Assistant.model; Accessible.name: "Model ID" }
            InputField { id: endpoint; Layout.fillWidth: true; visible: provider.currentIndex === 1 || provider.currentIndex === 4; placeholderText: provider.currentIndex === 4 ? "http://localhost:11434" : "https://your-provider.example/v1"; text: Assistant.endpoint; Accessible.name: "API base URL" }
            InputField { id: apiKey; Layout.fillWidth: true; placeholderText: "API key (leave blank to keep the saved key)"; echoMode: TextInput.Password; Accessible.name: "API key" }
            StyledText { Layout.fillWidth: true; text: "Only messages you send here go to the selected provider. Desktop context is never attached automatically."; wrapMode: Text.Wrap; font.pixelSize: 13; opacity: 0.7 }
            ActionButton {
                label: "Save provider"; symbol: "check"; enabled: !Assistant.working && provider.currentIndex > 0 && modelName.text.trim() !== ""
                onClicked: { Assistant.configure(["", "openai-compatible", "anthropic", "gemini", "ollama"][provider.currentIndex], modelName.text.trim(), endpoint.text.trim(), apiKey.text); apiKey.clear(); root.editing = false; }
            }
        }
    }
    ListView {
        id: conversation
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 12
        model: Assistant.messages
        onCountChanged: positionViewAtEnd()
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            required property var modelData
            width: conversation.width
            implicitHeight: message.implicitHeight + 30
            radius: 18
            color: modelData.role === "user" ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
            Column {
                id: message
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 15 }
                spacing: 8
                StyledText { text: modelData.role === "user" ? "You" : "Assistant"; opacity: 0.6; font.pixelSize: 12 }
                TextEdit {
                    width: parent.width
                    text: modelData.content
                    textFormat: TextEdit.PlainText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    color: Appearance.m3colors.m3onSurface
                    font.family: Appearance.font.family.main
                    font.pixelSize: 15
                }
            }
        }
        StyledText { anchors.centerIn: parent; visible: conversation.count === 0; text: "A little help, whenever you need it."; opacity: 0.5 }
    }
    StyledText { Layout.fillWidth: true; visible: Assistant.error !== ""; text: Assistant.error; color: Appearance.m3colors.m3error; wrapMode: Text.Wrap }
    StyledText { visible: Assistant.busy; text: "Waiting for " + Assistant.provider + "…"; opacity: 0.6 }
    InputArea {
        id: prompt
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        placeholderText: "Ask anything · Ctrl+Enter to send"
        wrapMode: TextEdit.Wrap
        enabled: Assistant.configured && !Assistant.busy
        Accessible.name: "Message"
        Keys.onPressed: event => { if (event.key === Qt.Key_Return && event.modifiers & Qt.ControlModifier) { Assistant.send(text); clear(); event.accepted = true; } }
    }
    RowLayout {
        ActionButton { label: "New conversation"; symbol: "add"; onClicked: Assistant.clear() }
        Item { Layout.fillWidth: true }
        ActionButton { visible: Assistant.busy; label: "Cancel"; onClicked: Assistant.cancel() }
        ActionButton { visible: !Assistant.busy; label: "Send"; symbol: "arrow_upward"; enabled: Assistant.configured && prompt.text.trim() !== ""; onClicked: { Assistant.send(prompt.text); prompt.clear(); } }
    }
}
