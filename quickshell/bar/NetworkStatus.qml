pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../icons"

Item {
    id: root
    width: Theme.fontSizeIcon + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property string activePopup
    signal togglePopup()
    property bool hovered: netMouse.containsMouse

    property string status: "disconnected"
    property string connectionName: ""
    property color iconColor: status === "disconnected" ? Theme.red : Theme.green

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let found = false;
                for (let line of lines) {
                    let parts = line.split(":");
                    if (parts.length >= 3 && parts[1] === "activated") {
                        let type = parts[0].toLowerCase();
                        if (type.includes("wireless") || type.includes("wifi") || type === "802-11-wireless") {
                            root.status = "wifi";
                        } else if (type.includes("ethernet") || type === "802-3-ethernet") {
                            root.status = "ethernet";
                        }
                        root.connectionName = parts[2];
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    root.status = "disconnected";
                    root.connectionName = "";
                }
            }
        }
    }

    Timer {
        interval: Config.networkPollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: netMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Item {
        id: netIcon
        width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
        anchors.centerIn: parent

        IconWifi {
            visible: root.status === "wifi"
            size: Theme.fontSizeIcon
            color: root.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconEthernet {
            visible: root.status === "ethernet"
            size: Theme.fontSizeIcon
            color: root.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconTriangleAlert {
            visible: root.status === "disconnected"
            size: Theme.fontSizeIcon
            color: root.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }
}
