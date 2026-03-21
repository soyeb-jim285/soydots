pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root
    width: batRow.implicitWidth + Theme.widgetPadding * 2
    height: parent?.height ?? Theme.barHeight
    visible: UPower.displayDevice.isPresent || sysBattery.percentage >= 0


    // Prefer UPower, fall back to /sys
    // UPower may return 0-1 (fraction) or 0-100 depending on version
    property real _rawPct: UPower.displayDevice.isPresent
        ? UPower.displayDevice.percentage
        : sysBattery.percentage
    property real percentage: _rawPct > 0 && _rawPct <= 1 ? _rawPct * 100 : _rawPct
    property bool charging: UPower.displayDevice.isPresent
        ? (UPower.displayDevice.state === UPowerDeviceState.Charging
            || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
        : sysBattery.charging

    property string batteryColor: {
        if (charging) return Theme.green;
        if (percentage > Config.batteryGreenThreshold) return Theme.green;
        if (percentage > Config.batteryYellowThreshold) return Theme.yellow;
        return Theme.red;
    }

    // Fallback: read from /sys/class/power_supply/BAT0
    QtObject {
        id: sysBattery
        property real percentage: -1
        property bool charging: false
    }

    FileView {
        id: batCapFile
        path: "/sys/class/power_supply/BAT0/capacity"
        onTextChanged: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) sysBattery.percentage = val;
        }
    }

    FileView {
        id: batStatusFile
        path: "/sys/class/power_supply/BAT0/status"
        onTextChanged: {
            sysBattery.charging = text().trim() === "Charging" || text().trim() === "Full";
        }
    }

    // Refresh /sys every 30s
    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { batCapFile.reload(); batStatusFile.reload(); }
    }


    Row {
        id: batRow
        anchors.centerIn: parent
        spacing: 5

        // SVG-style battery icon drawn with QML
        Item {
            width: 22; height: 12
            anchors.verticalCenter: parent.verticalCenter

            // Battery body outline
            Rectangle {
                id: batBody
                x: 0; y: 0
                width: 19; height: 12
                radius: 3
                color: "transparent"
                border.color: root.batteryColor
                border.width: 1.5
                Behavior on border.color { ColorAnimation { duration: 300 } }

                // Fill level
                Rectangle {
                    x: 2.5; y: 2.5
                    width: Math.max(0, (batBody.width - 5) * root.percentage / 100)
                    height: batBody.height - 5
                    radius: 1.5
                    color: root.batteryColor
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // Battery tip (positive terminal)
            Rectangle {
                x: batBody.width; y: 3
                width: 3; height: 6
                radius: 1
                color: root.batteryColor
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            // Charging bolt overlay
            Text {
                anchors.centerIn: batBody
                text: "\uf0e7"
                color: root.percentage > 50 ? Theme.crust : Theme.text
                font.pixelSize: 8
                font.family: Config.iconFont
                visible: root.charging
            }
        }

        Text {
            text: Math.round(root.percentage) + "%"
            color: Theme.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            anchors.verticalCenter: parent.verticalCenter
        }
    }

}
