import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root
    property string label
    property string symbol
    property real value: 0
    signal moved(real value)
    spacing: 10
    MaterialSymbol { text: root.symbol; iconSize: 20; opacity: root.enabled ? 1 : 0.4 }
    StyledSlider {
        Layout.fillWidth: true
        configuration: StyledSlider.Configuration.M
        value: root.value
        Accessible.name: root.label
        onMoved: root.moved(value)
    }
    StyledText { text: Math.round(root.value * 100) + "%"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight; opacity: root.enabled ? 0.8 : 0.4 }
}
