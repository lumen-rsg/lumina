import QtQuick
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root
    property string label: ""
    property string symbol: ""
    implicitHeight: 38
    implicitWidth: content.implicitWidth + 24
    buttonRadius: 16
    Accessible.name: label
    contentItem: Row {
        id: content
        spacing: 8
        MaterialSymbol { visible: root.symbol !== ""; text: root.symbol; iconSize: 20; anchors.verticalCenter: parent.verticalCenter }
        StyledText { text: root.label; anchors.verticalCenter: parent.verticalCenter }
    }
}
