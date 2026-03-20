pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import ".."

Item {
    id: root
    width: trayRow.implicitWidth
    height: parent?.height ?? Theme.barHeight

    property bool hovered: false
    signal trayMenuRequested(var menuHandle, real iconCenterX)

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
                    id: trayIcon
                    anchors.fill: parent

                    property string rawIcon: trayItem.modelData.icon ?? ""
                    source: {
                        if (rawIcon.includes("?path=")) {
                            let parts = rawIcon.split("?path=");
                            let name = parts[0];
                            let path = parts[1];
                            return path + "/" + name.slice(name.lastIndexOf("/") + 1);
                        }
                        return rawIcon;
                    }

                    sourceSize: Qt.size(Config.sysTrayIconSize * 2, Config.sysTrayIconSize * 2)
                    smooth: true
                    fillMode: Image.PreserveAspectFit
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

                    onContainsMouseChanged: {
                        if (containsMouse && trayItem.modelData.hasMenu) {
                            let globalX = trayItem.mapToItem(null, trayItem.width / 2, 0).x;
                            root.trayMenuRequested(trayItem.modelData.menu, globalX);
                        }
                        root.hovered = containsMouse;
                    }

                    onClicked: trayItem.modelData.activate()
                }
            }
        }
    }
}
