pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import ".."
import "../icons"

Item {
    id: root
    width: Config.speedWidgetWidth
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

    RowLayout {
        id: netRow
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        // Sparkline — download history
        Shape {
            id: sparkline
            Layout.preferredWidth: 40
            Layout.preferredHeight: Theme.fontSizeIcon
            Layout.alignment: Qt.AlignVCenter
            preferredRendererType: Shape.CurveRenderer

            property var history: NetSpeedSampler.rxHistory
            property real localMax: {
                let m = 1;
                for (let v of history) if (v > m) m = v;
                return m;
            }

            ShapePath {
                strokeColor: Theme.blue
                strokeWidth: 1.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: {
                        let pts = [];
                        let n = sparkline.history.length;
                        if (n < 2) return [Qt.point(0, sparkline.height), Qt.point(sparkline.width, sparkline.height)];
                        for (let i = 0; i < n; i++) {
                            let x = (i / (n - 1)) * sparkline.width;
                            let y = sparkline.height - (sparkline.history[i] / sparkline.localMax) * sparkline.height;
                            pts.push(Qt.point(x, y));
                        }
                        return pts;
                    }
                }
            }
        }

        // Existing wifi state icon
        Item {
            id: netIcon
            Layout.preferredWidth: Theme.fontSizeIcon
            Layout.preferredHeight: Theme.fontSizeIcon
            Layout.alignment: Qt.AlignVCenter

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

        // Rate text — dominant direction
        Text {
            id: rateText
            Layout.alignment: Qt.AlignVCenter
            property bool rxDominant: NetSpeedSampler.rxRateAvg >= NetSpeedSampler.txRateAvg
            text: NetSpeedSampler.formatRate(rxDominant ? NetSpeedSampler.rxRateAvg : NetSpeedSampler.txRateAvg)
            color: {
                if (!NetSpeedSampler.hasData || (NetSpeedSampler.rxRateAvg < 1024 && NetSpeedSampler.txRateAvg < 1024)) return Theme.overlay0;
                return rxDominant ? Theme.blue : Theme.green;
            }
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            font.bold: true
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
