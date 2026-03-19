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
        spacing: Config.sysTraySpacing

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem
                required property var modelData
                width: Config.sysTrayIconSize
                height: Config.sysTrayIconSize

                Image {
                    anchors.fill: parent
                    source: Quickshell.iconPath(trayItem.modelData.icon ?? "", "application-x-executable")
                    sourceSize: Qt.size(Config.sysTrayIconSize, Config.sysTrayIconSize)
                    opacity: trayMouse.containsMouse ? 1.0 : Config.sysTrayOpacity

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
