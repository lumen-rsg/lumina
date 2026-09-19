// Adapted from lumen-rsg/chroma c310258 (MIT); Cassiopeia integration.
// A compact, responsive reminder of Chroma's spatial controls.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

PanelWindow {
    id: root
    property bool opened: false
    signal closeRequested()

    readonly property var sections: Shortcuts.sections

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins {
        top: SpatialTheme.barHeight + 12
        right: 12
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0
    implicitWidth: Math.min(560, screen ? screen.width - 24 : 560)
    implicitHeight: Math.min(438,
        screen ? screen.height - SpatialTheme.barHeight - 24 : 438)
    color: "transparent"
    visible: root.opened
    WlrLayershell.namespace: "lumina:hints"

    Component.onCompleted: Shortcuts.refreshBindings()
    onVisibleChanged: {
        if (visible) {
            Shortcuts.refreshBindings();
            Qt.callLater(function() { card.forceActiveFocus() })
        }
    }


    Rectangle {
        id: card
        anchors.fill: parent
        radius: SpatialTheme.radiusLg
        color: SpatialTheme.glassBgStrong
        border { width: 1; color: SpatialTheme.glassBorder }
        focus: true
        Accessible.role: Accessible.Dialog
        Accessible.name: "Lumina controls guide"
        Accessible.description: "Keyboard and pointer controls for the spatial desktop"
        Keys.onEscapePressed: root.closeRequested()



        MouseArea {
            anchors.fill: parent
            onPressed: card.forceActiveFocus()
        }

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 11

            RowLayout {
                Layout.fillWidth: true
                spacing: 10



                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Find your way around"
                        color: SpatialTheme.fg
                        font.family: SpatialTheme.fontFamily
                        font.pixelSize: SpatialTheme.fontSizeLg
                        font.weight: SpatialTheme.fontWeightBold
                    }
                    Text {
                        text: "Hold Super to shape your workspace"
                        color: SpatialTheme.fgDim
                        font.family: SpatialTheme.fontFamily
                        font.pixelSize: SpatialTheme.fontSizeSm
                    }
                }

                Rectangle {
                    id: closeButton
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: SpatialTheme.radiusSm
                    color: closeMouse.containsMouse || activeFocus
                        ? SpatialTheme.glassHover : "transparent"
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: "Close controls guide"
                    Accessible.onPressAction: activate()
                    function activate(): void { root.closeRequested() }
                    Keys.onSpacePressed: activate()
                    Keys.onReturnPressed: activate()
                    border {
                        width: activeFocus ? 1 : 0
                        color: SpatialTheme.accent
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: SpatialTheme.fgDim
                        font.pixelSize: SpatialTheme.fontSizeSm
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: closeButton.forceActiveFocus()
                        onClicked: closeButton.activate()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: SpatialTheme.borderSubtle
            }

            Text { Layout.fillWidth: true; visible: Shortcuts.error !== ""; text: Shortcuts.error; color: SpatialTheme.accentWarn; wrapMode: Text.Wrap }
            Flickable {
                id: scroller
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: sectionGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                GridLayout {
                    id: sectionGrid
                    width: scroller.width
                    columns: root.width < 500 ? 1 : 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.sections

                        Rectangle {
                            id: sectionCard
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredHeight: sectionContent.implicitHeight + 18
                            radius: SpatialTheme.radius
                            color: SpatialTheme.bgRaised
                            border { width: 1; color: SpatialTheme.borderDefault }

                            ColumnLayout {
                                id: sectionContent
                                anchors {
                                    left: parent.left; right: parent.right
                                    top: parent.top; margins: 9
                                }
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: sectionCard.modelData.color
                                    }
                                    Text {
                                        text: sectionCard.modelData.title
                                        color: sectionCard.modelData.color
                                        font.family: SpatialTheme.fontFamily
                                        font.pixelSize: SpatialTheme.fontSizeSm
                                        font.weight: SpatialTheme.fontWeightBold
                                    }
                                }

                                Repeater {
                                    model: sectionCard.modelData.items

                                    RowLayout {
                                        id: shortcutRow
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: Math.min(
                                                132, shortcutKeys.implicitWidth + 12)
                                            Layout.preferredHeight: Math.max(23, shortcutKeys.implicitHeight + 8)
                                            radius: SpatialTheme.radiusSm
                                            color: SpatialTheme.bgOverlay
                                            border { width: 1; color: SpatialTheme.borderStrong }
                                            Text {
                                                id: shortcutKeys
                                                anchors.centerIn: parent
                                                width: parent.width - 8
                                                wrapMode: Text.WrapAnywhere
                                                horizontalAlignment: Text.AlignHCenter
                                                text: shortcutRow.modelData.keys
                                                color: SpatialTheme.fg
                                                font.family: SpatialTheme.fontMono
                                                font.pixelSize: 9
                                                font.weight: SpatialTheme.fontWeightMedium
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: shortcutRow.modelData.action
                                            color: SpatialTheme.fgDim
                                            wrapMode: Text.Wrap
                                            font.family: SpatialTheme.fontFamily
                                            font.pixelSize: SpatialTheme.fontSizeSm
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press  Esc  to drift back to the canvas"
                color: SpatialTheme.fgFaint
                font.family: SpatialTheme.fontFamily
                font.pixelSize: SpatialTheme.fontSizeXs
            }
        }
    }
}
