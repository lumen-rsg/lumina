import QtQuick
import qs.modules.common.widgets

// Keep the model binding separate from ConfigSwitch's user-editable checked state.
ConfigSwitch {
    id: root
    property bool value: false
    signal edited(bool value)
    onValueChanged: checked = value
    Component.onCompleted: checked = value
    onCheckedChanged: if (checked !== value) edited(checked)
}
