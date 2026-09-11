import QtQuick
import QtQuick.Controls
import qs.modules.common

TextField {
    color: Appearance.m3colors.m3onSurface
    placeholderTextColor: Appearance.m3colors.m3onSurfaceVariant
    selectionColor: Appearance.m3colors.m3primary
    selectedTextColor: Appearance.m3colors.m3onPrimary
    font.family: Appearance.font.family.main
    font.pixelSize: 15
    padding: 14
    background: Rectangle {
        radius: 12
        color: Appearance.colors.colLayer1
        border.color: parent.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outlineVariant
    }
}
