pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import ".."

Item {
    id: root
    width: trayRow.implicitWidth
    height: parent?.height ?? Theme.barHeight

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem
                required property var modelData
                width: 20
                height: 20

                Image {
                    anchors.fill: parent
                    source: Quickshell.iconPath(trayItem.modelData.icon ?? "", "application-x-executable")
                    sourceSize: Qt.size(20, 20)
                    opacity: trayMouse.containsMouse ? 1.0 : 0.7

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animDurationFast }
                    }
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: trayItem.modelData.activate()
                }
            }
        }
    }
}
