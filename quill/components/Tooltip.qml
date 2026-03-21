import QtQuick
import ".."

Item {
    id: root
    property Item target: parent
    property string text: ""
    z: 1000
    x: target ? (target.width - tooltipBg.width) / 2 : 0
    y: target ? -tooltipBg.height - 6 : 0
    Rectangle {
        id: tooltipBg
        width: tooltipText.implicitWidth + Theme.spacingMd * 2
        height: tooltipText.implicitHeight + Theme.spacing * 2
        radius: Theme.radiusSm
        color: Theme.surface2
        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.text
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
}
