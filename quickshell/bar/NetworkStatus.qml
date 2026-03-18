pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root
    width: netIcon.implicitWidth + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    property string status: "disconnected"
    property string connectionName: ""
    property string icon: {
        if (status === "wifi") return "\uf1eb";
        if (status === "ethernet") return "\uf796";
        return "\uf071";
    }
    property string iconColor: status === "disconnected" ? Theme.red : Theme.green

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
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Text {
        id: netIcon
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: Theme.fontSizeIcon
        font.family: Theme.iconFont
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }
}
