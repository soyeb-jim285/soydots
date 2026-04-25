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
    property color iconColor: status === "disconnected" ? Theme.red : Theme.text

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let ethernet = null;
                let wifi = null;
                let other = null;
                for (let line of lines) {
                    let parts = line.split(":");
                    if (parts.length < 3 || parts[1] !== "activated") continue;
                    let type = parts[0].toLowerCase();
                    let name = parts[2];
                    if (type.includes("ethernet") || type === "802-3-ethernet") {
                        if (!ethernet) ethernet = name;
                    } else if (type.includes("wireless") || type.includes("wifi") || type === "802-11-wireless") {
                        if (!wifi) wifi = name;
                    } else if (type === "loopback" || type === "bridge" || type === "tun") {
                        // ignore virtual/local interfaces
                    } else {
                        // vpn, wireguard, gsm, etc.
                        if (!other) other = name;
                    }
                }
                if (ethernet) {
                    root.status = "ethernet";
                    root.connectionName = ethernet;
                    root.signalStrength = 0;
                } else if (wifi) {
                    root.status = "wifi";
                    root.connectionName = wifi;
                    signalProc.running = true;
                } else if (other) {
                    root.status = "ethernet";
                    root.connectionName = other;
                    root.signalStrength = 0;
                } else {
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

        IconWifiSector {
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
