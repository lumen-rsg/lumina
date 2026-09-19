// Adapted from lumen-rsg/chroma c310258 (MIT); Cassiopeia integration.
// Full-canvas overview and off-screen window recovery.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import qs.panels

Item {
    id: root
    property bool opened: false
    property var output
    signal closeRequested()

    PanelWindow {
            id: overlay
            objectName: "canvasOverlay"
            screen: root.output
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "lumina:overview"
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            visible: root.opened

            readonly property real safeZoom: Math.max(Chroma.zoom, 0.01)
            readonly property real viewportWidth:
                (Chroma.viewportWidth > 0
                    ? Chroma.viewportWidth : width) / safeZoom
            readonly property real viewportHeight:
                (Chroma.viewportHeight > 0
                    ? Chroma.viewportHeight : height) / safeZoom
            readonly property real rawLeft: {
                var value = Chroma.viewportX - viewportWidth / 2
                for (var i = 0; i < Chroma.windows.length; ++i)
                    value = Math.min(value, Chroma.windows[i].x)
                for (var point = 0; point < Chroma.teleports.length; ++point)
                    value = Math.min(value, Chroma.teleports[point].x)
                return value
            }
            readonly property real rawTop: {
                var value = Chroma.viewportY - viewportHeight / 2
                for (var i = 0; i < Chroma.windows.length; ++i)
                    value = Math.min(value, Chroma.windows[i].y)
                for (var point = 0; point < Chroma.teleports.length; ++point)
                    value = Math.min(value, Chroma.teleports[point].y)
                return value
            }
            readonly property real rawRight: {
                var value = Chroma.viewportX + viewportWidth / 2
                for (var i = 0; i < Chroma.windows.length; ++i) {
                    var window = Chroma.windows[i]
                    value = Math.max(value, window.x + window.width)
                }
                for (var point = 0; point < Chroma.teleports.length; ++point)
                    value = Math.max(value, Chroma.teleports[point].x)
                return value
            }
            readonly property real rawBottom: {
                var value = Chroma.viewportY + viewportHeight / 2
                for (var i = 0; i < Chroma.windows.length; ++i) {
                    var window = Chroma.windows[i]
                    value = Math.max(value, window.y + window.height)
                }
                for (var point = 0; point < Chroma.teleports.length; ++point)
                    value = Math.max(value, Chroma.teleports[point].y)
                return value
            }
            readonly property real contentPadding:
                Math.max(Math.max(rawRight - rawLeft, rawBottom - rawTop) * 0.06, 80)
            readonly property real contentLeft: rawLeft - contentPadding
            readonly property real contentTop: rawTop - contentPadding
            readonly property real contentWidth: rawRight - rawLeft + contentPadding * 2
            readonly property real contentHeight: rawBottom - rawTop + contentPadding * 2
            property int selectedTeleportId: 0
            property string windowQuery: ""
            onSelectedTeleportIdChanged: {
                if (selectedTeleportId <= 0) return
                for (var index = 0; index < Chroma.teleports.length; ++index) {
                    if (Chroma.teleports[index].id === selectedTeleportId) {
                        teleportName.text = Chroma.teleports[index].name || ""
                        Qt.callLater(function() { teleportName.forceActiveFocus() })
                        return
                    }
                }
            }
            readonly property var filteredWindows: {
                var query = windowQuery.trim().toLowerCase()
                if (query.length === 0)
                    return Chroma.windows
                var result = []
                for (var index = 0; index < Chroma.windows.length; ++index) {
                    var window = Chroma.windows[index]
                    var haystack = ((window.title || "") + " "
                        + (window.app_id || "")).toLowerCase()
                    if (haystack.indexOf(query) >= 0)
                        result.push(window)
                }
                return result
            }

            function forceOverviewFocus(): void { overviewCard.forceActiveFocus() }
            function prepareOpen(): void {
                forceOverviewFocus()
            }
            function closeAndRun(action): void {
                Chroma.action(action)
                root.closeRequested()
            }
            onVisibleChanged: {
                if (visible) Qt.callLater(prepareOpen)
            }
            Component.onCompleted: {
                if (visible) Qt.callLater(prepareOpen)
            }

            Rectangle {
                anchors.fill: parent
                color: SpatialTheme.scrim
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                id: overviewCard
                anchors.centerIn: parent
                width: Math.min(1100, overlay.width - 24)
                height: Math.min(760, overlay.height - 24)
                radius: SpatialTheme.radiusLg
                color: SpatialTheme.glassBgStrong
                border { width: 1; color: SpatialTheme.glassBorder }
                focus: true
                Accessible.role: Accessible.Dialog
                Accessible.name: "Canvas overview"
                Keys.onEscapePressed: root.closeRequested()



                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors { fill: parent; margins: 18 }
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Canvas overview"
                            color: SpatialTheme.fg
                            font.family: SpatialTheme.fontFamily
                            font.pixelSize: SpatialTheme.fontSizeLg
                            font.weight: SpatialTheme.fontWeightBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Chroma.windows.length
                                + (Chroma.windows.length === 1
                                    ? " window  ·  " : " windows  ·  ")
                                + Chroma.teleports.length
                                + (Chroma.teleports.length === 1
                                    ? " teleport point  ·  " : " teleport points  ·  ")
                                + Math.round(Chroma.zoom * 100) + "%"
                            color: SpatialTheme.fgDim
                            horizontalAlignment: Text.AlignRight
                            font.family: SpatialTheme.fontMono
                            font.pixelSize: SpatialTheme.fontSizeSm
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: SpatialTheme.radiusSm
                        color: SpatialTheme.bgRaised
                        border.color: searchInput.activeFocus
                            ? SpatialTheme.accent : SpatialTheme.borderDefault
                        TextInput {
                            id: searchInput
                            objectName: "windowSearch"
                            anchors { fill: parent; margins: 9 }
                            color: SpatialTheme.fg
                            font.family: SpatialTheme.fontFamily
                            font.pixelSize: SpatialTheme.fontSizeSm
                            clip: true
                            text: overlay.windowQuery
                            onTextChanged: overlay.windowQuery = text
                            Accessible.name: "Search windows by title or application"
                        }
                        Text {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 }
                            visible: searchInput.text.length === 0
                            text: "Search windows by title or application…"
                            color: SpatialTheme.fgFaint
                            font.family: SpatialTheme.fontFamily
                            font.pixelSize: SpatialTheme.fontSizeSm
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Chroma.windowsTruncated
                        text: "Partial map · showing the first 128 mapped windows. Use reset-view for all content."
                        color: SpatialTheme.accentWood
                        font.family: SpatialTheme.fontFamily
                        font.pixelSize: SpatialTheme.fontSizeSm
                        Accessible.role: Accessible.StaticText
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [
                                {label: "−", action: "zoom_out"}, {label: "100%", action: "zoom_reset"},
                                {label: "+", action: "zoom_in"}, {label: "Save point", action: "mark_teleport"},
                                {label: "Grid", action: "tile_grid"}, {label: "Columns", action: "tile_columns"},
                                {label: "Restore", action: "restore_layout"}
                            ]
                            ActionButton {
                                required property var modelData
                                label: modelData.label
                                enabled: Chroma.connected && (modelData.action !== "restore_layout" || Chroma.canRestoreArrangement)
                                onClicked: Chroma.action(modelData.action)
                            }
                        }
                        ActionButton { label: "Close"; symbol: "close"; onClicked: root.closeRequested() }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !Chroma.connected || Chroma.error !== ""
                        text: Chroma.error || "Connecting to Chroma…"
                        color: SpatialTheme.accentWarn
                        wrapMode: Text.Wrap
                    }
                    Rectangle {
                        id: plot
                        objectName: "canvasPlot"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 100
                        radius: SpatialTheme.radius
                        color: SpatialTheme.bg
                        border.color: SpatialTheme.borderDefault
                        clip: true

                        readonly property real mapScale: Math.min(
                            (width - 32) / Math.max(overlay.contentWidth, 1),
                            (height - 32) / Math.max(overlay.contentHeight, 1))
                        readonly property real offsetX:
                            (width - overlay.contentWidth * mapScale) / 2
                        readonly property real offsetY:
                            (height - overlay.contentHeight * mapScale) / 2
                        function mapX(value): real {
                            return offsetX + (value - overlay.contentLeft) * mapScale
                        }
                        function mapY(value): real {
                            return offsetY + (value - overlay.contentTop) * mapScale
                        }
                        function canvasX(value): real {
                            return overlay.contentLeft
                                + (value - offsetX) / Math.max(mapScale, 0.0001)
                        }
                        function canvasY(value): real {
                            return overlay.contentTop
                                + (value - offsetY) / Math.max(mapScale, 0.0001)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: function(mouse) {
                                Chroma.action("move_view "
                                    + plot.canvasX(mouse.x) + " "
                                    + plot.canvasY(mouse.y))
                                root.closeRequested()
                            }
                        }

                        // Current viewport, shown behind window cards.
                        Rectangle {
                            x: plot.mapX(Chroma.viewportX - overlay.viewportWidth / 2)
                            y: plot.mapY(Chroma.viewportY - overlay.viewportHeight / 2)
                            width: Math.max(2, overlay.viewportWidth * plot.mapScale)
                            height: Math.max(2, overlay.viewportHeight * plot.mapScale)
                            color: SpatialTheme.viewportFill
                            border { width: 2; color: SpatialTheme.accent }
                            radius: SpatialTheme.radiusSm
                        }

                        Repeater {
                            model: overlay.filteredWindows
                            delegate: Rectangle {
                                id: windowCard
                                required property var modelData
                                x: plot.mapX(modelData.x)
                                y: plot.mapY(modelData.y)
                                width: Math.max(8, modelData.width * plot.mapScale)
                                height: Math.max(6, modelData.height * plot.mapScale)
                                radius: 3
                                color: SpatialTheme.bgOverlay
                                opacity: modelData.stack > 0 ? 0.72 : 0.9
                                border {
                                    width: windowCard.activeFocus
                                        || modelData.focused ? 3 : 1
                                    color: windowCard.activeFocus
                                        ? SpatialTheme.accent : modelData.focused
                                        ? SpatialTheme.fg : modelData.attention
                                        ? SpatialTheme.accentWarn : SpatialTheme.borderStrong
                                }
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: (modelData.title || "Untitled window")
                                    + ", " + (modelData.app_id || "unknown application")
                                    + (modelData.focused ? ", focused" : "")
                                    + (modelData.attention ? ", requests attention" : "")
                                Accessible.description: "Go to this window"
                                Accessible.onPressAction: activate()
                                function activate(): void {
                                    overlay.closeAndRun(
                                        "focus_window " + modelData.id)
                                }
                                Keys.onSpacePressed: activate()
                                Keys.onReturnPressed: activate()

                                Column {
                                    anchors { fill: parent; margins: 4 }
                                    spacing: 1
                                    clip: true
                                    Text {
                                        width: parent.width
                                        textFormat: Text.PlainText
                                    text: windowCard.modelData.title || "Untitled"
                                        color: SpatialTheme.fg
                                        elide: Text.ElideRight
                                        font.family: SpatialTheme.fontFamily
                                        font.pixelSize: Math.max(8, Math.min(
                                            SpatialTheme.fontSizeSm, windowCard.height * 0.22))
                                        font.weight: SpatialTheme.fontWeightBold
                                    }
                                    Text {
                                        width: parent.width
                                        textFormat: Text.PlainText
                                    text: windowCard.modelData.app_id || "Unknown app"
                                        color: SpatialTheme.fgDim
                                        elide: Text.ElideRight
                                        font.family: SpatialTheme.fontMono
                                        font.pixelSize: Math.max(7, Math.min(
                                            SpatialTheme.fontSizeXs, windowCard.height * 0.18))
                                    }
                                }

                                Row {
                                    z: 2
                                    anchors { right: parent.right; bottom: parent.bottom; margins: 3 }
                                    spacing: 3
                                    Rectangle {
                                        activeFocusOnTab: true
                                        width: 34; height: 20; radius: 3
                                        color: SpatialTheme.accentSoft
                                        Accessible.role: Accessible.Button
                                        Accessible.name: "Bring here " + (windowCard.modelData.title || "window")
                                        Accessible.onPressAction: activate()
                                        function activate(): void {
                                            overlay.closeAndRun("bring_window " + windowCard.modelData.id)
                                        }
                                        Keys.onSpacePressed: activate()
                                        Keys.onReturnPressed: activate()
                                        Text { anchors.centerIn: parent; text: "Bring"; color: SpatialTheme.fg; font.pixelSize: 8 }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: function(mouse) {
                                                mouse.accepted = true
                                                parent.activate()
                                            }
                                        }
                                    }
                                    Rectangle {
                                        activeFocusOnTab: true
                                        width: 20; height: 20; radius: 3
                                        color: SpatialTheme.bgRaised
                                        Accessible.role: Accessible.Button
                                        Accessible.name: "Close " + (windowCard.modelData.title || "window")
                                        Accessible.onPressAction: activate()
                                        function activate(): void {
                                            Chroma.action("close_window " + windowCard.modelData.id)
                                        }
                                        Keys.onSpacePressed: activate()
                                        Keys.onReturnPressed: activate()
                                        Text { anchors.centerIn: parent; text: "×"; color: SpatialTheme.fg; font.pixelSize: 12 }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: function(mouse) {
                                                mouse.accepted = true
                                                parent.activate()
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: windowCard.forceActiveFocus()
                                    onClicked: windowCard.activate()
                                }
                            }
                        }

                        Repeater {
                            model: Chroma.teleports
                            delegate: Rectangle {
                                id: teleportMarker
                                required property var modelData
                                x: plot.mapX(modelData.x) - width / 2
                                y: plot.mapY(modelData.y) - height / 2
                                width: 24
                                height: 24
                                radius: 12
                                color: SpatialTheme.groupColors[(modelData.id - 1)
                                    % SpatialTheme.groupColors.length]
                                border {
                                    width: teleportMarker.activeFocus ? 3 : 2
                                    color: teleportMarker.activeFocus
                                        ? SpatialTheme.accent : SpatialTheme.fg
                                }
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.name || "Teleport " + modelData.id
                                Accessible.description: "Teleport to this saved canvas area; F2 to rename or remove"
                                Keys.onPressed: event => { if (event.key === Qt.Key_F2) { overlay.selectedTeleportId = modelData.id; event.accepted = true; } }
                                Accessible.onPressAction: activate()
                                function activate(): void {
                                    overlay.closeAndRun(
                                        "jump_teleport " + modelData.id)
                                }
                                Keys.onSpacePressed: activate()
                                Keys.onReturnPressed: activate()

                                Text {
                                    anchors.centerIn: parent
                                    text: teleportMarker.modelData.id
                                    color: SpatialTheme.bg
                                    font.family: SpatialTheme.fontMono
                                    font.pixelSize: SpatialTheme.fontSizeXs
                                    font.weight: SpatialTheme.fontWeightHeavy
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onPressed: teleportMarker.forceActiveFocus()
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            overlay.selectedTeleportId = teleportMarker.modelData.id
                                        } else {
                                            teleportMarker.activate()
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: Chroma.windows.length === 0
                            text: "No mapped windows yet"
                            textFormat: Text.PlainText
                            color: SpatialTheme.fgFaint
                            font.family: SpatialTheme.fontFamily
                            font.pixelSize: SpatialTheme.fontSizeMd
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: overlay.selectedTeleportId > 0
                        spacing: 8
                        Text { text: "Point " + overlay.selectedTeleportId; color: SpatialTheme.fgDim }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: SpatialTheme.radiusSm
                            color: SpatialTheme.bgRaised
                            border.color: teleportName.activeFocus ? SpatialTheme.accent : SpatialTheme.borderDefault
                            TextInput {
                                id: teleportName
                                objectName: "teleportName"
                                anchors { fill: parent; margins: 8 }
                                color: SpatialTheme.fg
                                maximumLength: 64
                                Accessible.name: "Teleport point name"
                                Keys.onReturnPressed: {
                                    Chroma.action("rename_teleport "
                                        + overlay.selectedTeleportId + " " + text)
                                    overlay.selectedTeleportId = 0
                                }
                            }
                        }
                        Rectangle {
                            width: 72; height: 34; radius: SpatialTheme.radiusSm
                            color: SpatialTheme.accentSoft
                            Accessible.role: Accessible.Button
                            Accessible.name: "Save teleport point name"
                            activeFocusOnTab: true
                            Accessible.onPressAction: activate()
                            Keys.onReturnPressed: activate()
                            Keys.onSpacePressed: activate()
                            function activate() { Chroma.action("rename_teleport " + overlay.selectedTeleportId + " " + teleportName.text); overlay.selectedTeleportId = 0; }
                            Text { anchors.centerIn: parent; text: "Rename"; color: SpatialTheme.fg }
                            MouseArea { anchors.fill: parent; onClicked: {
                                Chroma.action("rename_teleport "
                                    + overlay.selectedTeleportId + " " + teleportName.text)
                                overlay.selectedTeleportId = 0
                            } }
                        }
                        Rectangle {
                            width: 66; height: 34; radius: SpatialTheme.radiusSm
                            color: SpatialTheme.bgRaised
                            Accessible.role: Accessible.Button
                            Accessible.name: "Remove teleport point"
                            activeFocusOnTab: true
                            Accessible.onPressAction: activate()
                            Keys.onReturnPressed: activate()
                            Keys.onSpacePressed: activate()
                            function activate() { Chroma.action("remove_teleport " + overlay.selectedTeleportId); overlay.selectedTeleportId = 0; }
                            Text { anchors.centerIn: parent; text: "Remove"; color: SpatialTheme.fg }
                            MouseArea { anchors.fill: parent; onClicked: {
                                Chroma.action("remove_teleport " + overlay.selectedTeleportId)
                                overlay.selectedTeleportId = 0
                            } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: "Select a window to go there · right-click a point to rename or remove it."
                            color: SpatialTheme.fgDim
                            font.family: SpatialTheme.fontFamily
                            font.pixelSize: SpatialTheme.fontSizeSm
                        }

                        Repeater {
                            model: [
                                { label: "Previous point", action: "jump_prev_teleport" },
                                { label: "Next point", action: "jump_next_teleport" },
                                { label: "Fit all windows", action: "reset_view" }
                            ]
                            delegate: Rectangle {
                                id: actionButton
                                required property var modelData
                                width: actionLabel.implicitWidth + 22
                                height: 34
                                radius: SpatialTheme.radiusSm
                                color: actionMouse.containsMouse
                                    ? SpatialTheme.glassActive : SpatialTheme.bgRaised
                                border.color: modelData.action === "reset_view"
                                    || actionButton.activeFocus
                                    ? SpatialTheme.accent : SpatialTheme.borderDefault
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.label
                                Accessible.onPressAction: activate()
                                function activate(): void {
                                    overlay.closeAndRun(modelData.action)
                                }
                                Keys.onSpacePressed: activate()
                                Keys.onReturnPressed: activate()

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionButton.modelData.label
                                    color: SpatialTheme.fg
                                    font.family: SpatialTheme.fontFamily
                                    font.pixelSize: SpatialTheme.fontSizeSm
                                    font.weight: SpatialTheme.fontWeightBold
                                }
                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: actionButton.forceActiveFocus()
                                    onClicked: actionButton.activate()
                                }
                            }
                        }
                    }
                }
            }
    }
}
