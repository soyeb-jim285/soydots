pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root
    width: btIcon.implicitWidth + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    property bool powered: false
    property bool connected: false
    property string deviceName: ""

    property string icon: {
        if (!powered) return "\uf293";
        if (connected) return "\uf294";
        return "\uf293";
    }
    property color iconColor: {
        if (!powered) return Theme.overlay0;
        if (connected) return Theme.blue;
        return Theme.text;
    }

    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep -E 'Powered:' && bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                root.powered = false;
                root.connected = false;
                root.deviceName = "";
                for (let line of lines) {
                    if (line.includes("Powered: yes")) {
                        root.powered = true;
                    }
                    if (line.startsWith("Device ")) {
                        root.connected = true;
                        root.deviceName = line.replace(/Device [A-F0-9:]+\s*/, "");
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: btMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Text {
        id: btIcon
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: Theme.fontSizeIcon
        font.family: Theme.iconFont
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }

    MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: {
            if (root.powered) {
                btOffProc.running = true;
            } else {
                btOnProc.running = true;
            }
        }
    }

    Process {
        id: btOnProc
        command: ["bluetoothctl", "power", "on"]
        onRunningChanged: if (!running) btProc.running = true
    }

    Process {
        id: btOffProc
        command: ["bluetoothctl", "power", "off"]
        onRunningChanged: if (!running) btProc.running = true
    }
}
