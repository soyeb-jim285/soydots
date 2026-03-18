pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: popup
    implicitWidth: 240
    implicitHeight: contentCol.implicitHeight + 32
    color: "transparent"

    property real percentage: 0
    property bool charging: false
    property string timeRemaining: {
        let secs = charging ? UPower.displayDevice.timeToFull : UPower.displayDevice.timeToEmpty;
        if (secs <= 0) return "N/A";
        let hours = Math.floor(secs / 3600);
        let mins = Math.floor((secs % 3600) / 60);
        if (hours > 0) return hours + "h " + mins + "m";
        return mins + "m";
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: 12
        border.color: Theme.surface1
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: "Battery"
                color: Theme.text
                font.pixelSize: 14
                font.family: Theme.fontFamily
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Theme.surface1

                Rectangle {
                    width: parent.width * (popup.percentage / 100)
                    height: parent.height
                    radius: 4
                    color: popup.percentage > 60 ? Theme.green
                        : popup.percentage > 20 ? Theme.yellow
                        : Theme.red
                    Behavior on width { NumberAnimation { duration: Theme.animDuration } }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: Math.round(popup.percentage) + "%"
                    color: Theme.text
                    font.pixelSize: 22
                    font.family: Theme.fontFamily
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: popup.charging ? "Charging" : "Discharging"
                        color: popup.charging ? Theme.green : Theme.subtext0
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: popup.charging ? "Full in " + popup.timeRemaining : popup.timeRemaining + " left"
                        color: Theme.subtext0
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }
}
