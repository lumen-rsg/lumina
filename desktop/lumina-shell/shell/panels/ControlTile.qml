// Adapted from upstream ii AndroidQuickToggleButton: split icon/menu pill.
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

GroupButton {
    id: root
    property string label
    property string detail
    property string symbol
    property bool expanded: true
    property bool hasMenu: false
    signal activated()
    signal openMenu()
    baseWidth: expanded ? 166 : 62
    baseHeight: 62
    Layout.fillHeight: false
    buttonRadius: toggled ? 20 : 31
    buttonRadiusPressed: 16
    horizontalPadding: 6
    verticalPadding: 6
    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: hasMenu ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
    Accessible.name: label + (detail ? ", " + detail : "")
    Accessible.role: Accessible.Button
    onClicked: hasMenu ? openMenu() : activated()
    altAction: () => root.openMenu()
    opacity: enabled ? 1 : 0.45
    contentItem: RowLayout {
        spacing: 8
        Rectangle {
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            radius: root.toggled ? 16 : 24
            color: root.toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
            MaterialSymbol { anchors.centerIn: parent; text: root.symbol; iconSize: 24; color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2 }
            MouseArea { anchors.fill: parent; enabled: root.hasMenu; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
        }
        ColumnLayout {
            visible: root.expanded
            Layout.fillWidth: true; spacing: 0
            StyledText { Layout.fillWidth: true; text: root.label; font.weight: Font.DemiBold; font.pixelSize: 14; elide: Text.ElideRight; color: root.toggled && !root.hasMenu ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2 }
            StyledText { Layout.fillWidth: true; text: root.detail; font.pixelSize: 11; elide: Text.ElideRight; opacity: 0.7; color: root.toggled && !root.hasMenu ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2 }
        }
    }
    StyledToolTip { text: root.label + (root.detail ? " · " + root.detail : "") }
}
