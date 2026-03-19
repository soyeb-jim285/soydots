pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import ".."
import "../popups"

Item {
    id: root
    width: batRow.implicitWidth + Theme.widgetPadding * 2
    height: parent?.height ?? Theme.barHeight
    visible: UPower.displayDevice.isPresent

    required property var barWindow
    required property string activePopup
    signal togglePopup()

    property real percentage: UPower.displayDevice.percentage
    property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
        || UPower.displayDevice.state === UPowerDeviceState.FullyCharged

    property string batteryColor: {
        if (charging) return Theme.green;
        if (percentage > Config.batteryGreenThreshold) return Theme.green;
        if (percentage > Config.batteryYellowThreshold) return Theme.yellow;
        return Theme.red;
    }

    property string icon: {
        if (charging) return "\uf0e7";
        if (percentage > 80) return "\uf240";
        if (percentage > Config.batteryGreenThreshold) return "\uf241";
        if (percentage > 40) return "\uf242";
        if (percentage > Config.batteryYellowThreshold) return "\uf243";
        return "\uf244";
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: batMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Row {
        id: batRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: root.batteryColor
            font.pixelSize: Theme.fontSizeIcon
            font.family: Theme.iconFont
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }

        Text {
            text: Math.round(root.percentage) + "%"
            color: Theme.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    BatteryPopup {
        id: batteryPopup
        anchor.window: root.barWindow
        anchor.rect.x: root.x + root.width / 2 - implicitWidth / 2
        anchor.rect.y: Theme.barHeight + 4
        visible: root.activePopup === "battery"
        percentage: root.percentage
        charging: root.charging
    }
}
