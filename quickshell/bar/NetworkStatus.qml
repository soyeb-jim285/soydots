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
    property int signalStrength: 0
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
                            signalProc.running = true;
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
                    root.signalStrength = 0;
                }
            }
        }
    }

    Process {
        id: signalProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                for (let line of lines) {
                    let parts = line.split(":");
                    if (parts.length >= 2 && parts[0] === "*") {
                        root.signalStrength = parseInt(parts[1]) || 0;
                        return;
                    }
                }
                root.signalStrength = 0;
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

        IconWifiStrength {
            visible: root.status === "wifi"
            size: Theme.fontSizeIcon
            signal: root.signalStrength
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
        IconWifiOff {
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
