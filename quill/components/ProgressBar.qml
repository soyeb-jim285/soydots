import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property real value: 0.0
    property string variant: "primary"
    property bool indeterminate: false
    implicitHeight: 6
    Layout.fillWidth: true
    radius: Theme.radiusFull
    color: Theme.surface1
    property color _fillColor: {
        switch (variant) {
            case "success": return Theme.success;
            case "warning": return Theme.warning;
            case "error": return Theme.error;
            default: return Theme.primary;
        }
    }
    Rectangle {
        visible: !root.indeterminate
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: Theme.radiusFull
        color: root._fillColor
        Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        id: indeterminateBar
        visible: root.indeterminate
        width: parent.width * 0.3
        height: parent.height
        radius: Theme.radiusFull
        color: root._fillColor
        SequentialAnimation on x {
            running: root.indeterminate
            loops: Animation.Infinite
            NumberAnimation {
                from: -indeterminateBar.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutCubic
            }
        }
    }
    clip: true
}
