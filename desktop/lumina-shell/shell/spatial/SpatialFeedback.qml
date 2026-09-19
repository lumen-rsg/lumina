// Adapted from lumen-rsg/chroma c310258 (MIT); Cassiopeia integration.
// Short-lived compositor operation feedback, mirrored on every output.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

PanelWindow {
    id: root
    anchors { top: true }
    margins { top: SpatialTheme.barHeight + 14 }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    implicitWidth: Math.min(380, screen ? screen.width - 32 : 380)
    implicitHeight: Math.max(64, feedbackText.implicitHeight + 24)
    color: "transparent"
    visible: Chroma.feedback !== null
    mask: Region {}
    WlrLayershell.namespace: "lumina:feedback"

    readonly property string kind:
        Chroma.feedback ? Chroma.feedback.kind : ""
    readonly property string message:
        Chroma.feedback ? Chroma.feedback.message : ""
    readonly property color operationColor: {
        switch (kind) {
        case "warning": return SpatialTheme.accentWarn
        case "teleport": return SpatialTheme.accentPurple
        case "stack": return SpatialTheme.accentCyan
        case "resize": return SpatialTheme.accentAlt
        case "window": return SpatialTheme.accentWarn
        case "move": return SpatialTheme.accent
        case "pan": return SpatialTheme.accent
        default: return SpatialTheme.accent
        }
    }
    readonly property string operationGlyph: {
        switch (kind) {
        case "warning": return "!"
        case "teleport": return "T"
        case "stack": return "S"
        case "resize": return "↘"
        case "move": return "↔"
        case "pan": return "✥"
        case "zoom": return "%"
        case "window": return "□"
        default: return "·"
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: SpatialTheme.radius
        color: SpatialTheme.glassBgStrong
        border { width: 1; color: root.operationColor }
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: SpatialTheme.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: SpatialTheme.animNormal; easing.type: Easing.OutBack }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 16 }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: SpatialTheme.radiusSm
                color: root.operationColor

                Text {
                    anchors.centerIn: parent
                    text: root.operationGlyph
                    color: SpatialTheme.bg
                    font.family: SpatialTheme.fontMono
                    font.pixelSize: SpatialTheme.fontSizeMd
                    font.weight: SpatialTheme.fontWeightHeavy
                }
            }

            Text {
                Layout.fillWidth: true
                id: feedbackText
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                text: root.message
                color: SpatialTheme.fg
                font.family: SpatialTheme.fontFamily
                font.pixelSize: SpatialTheme.fontSize
                font.weight: SpatialTheme.fontWeightBold
            }

            Text {
                text: root.kind.charAt(0).toUpperCase() + root.kind.slice(1)
                color: root.operationColor
                font.family: SpatialTheme.fontFamily
                font.pixelSize: SpatialTheme.fontSizeXs
                font.weight: SpatialTheme.fontWeightBold
            }
        }
    }
}
