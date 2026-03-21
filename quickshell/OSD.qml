pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "icons"

Scope {
    id: root

    property string osdType: ""  // "volume", "brightness", "capslock", "numlock"
    property real osdValue: 0
    property bool osdBool: false
    property bool osdVisible: false

    // Volume tracking
    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    property real currentVolume: sink?.audio?.volume ?? 0
    property bool currentMuted: sink?.audio?.muted ?? false
    property bool volumeReady: false

    Timer {
        id: readyDelay
        interval: Config.osdReadyDelay
        running: true
        onTriggered: root.volumeReady = true
    }

    onCurrentVolumeChanged: {
        if (!volumeReady) return;
        osdType = "volume";
        osdValue = currentVolume;
        osdBool = currentMuted;
        showOsd();
    }

    onCurrentMutedChanged: {
        if (!volumeReady) return;
        osdType = "volume";
        osdValue = currentVolume;
        osdBool = currentMuted;
        showOsd();
    }

    // Brightness IPC
    IpcHandler {
        target: "osd"
        function brightness(): void {
            brightnessProc.running = true;
        }
        function capslock(): void {
            capslockDelay.restart();
        }
        function numlock(): void {
            numlockDelay.restart();
        }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Format: device,class,current,percentage,max
                let parts = this.text.trim().split(",");
                if (parts.length >= 4) {
                    let pct = parseInt(parts[3]);
                    root.osdType = "brightness";
                    root.osdValue = pct / 100;
                    root.showOsd();
                }
            }
        }
    }

    Timer {
        id: capslockDelay
        interval: 100
        onTriggered: capslockProc.running = true
    }

    Timer {
        id: numlockDelay
        interval: 100
        onTriggered: numlockProc.running = true
    }

    Process {
        id: capslockProc
        command: ["bash", "-c", "hyprctl devices -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print('1' if any(k.get('capsLock') for k in d.get('keyboards',[])) else '0')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.osdType = "capslock";
                root.osdBool = this.text.trim() === "1";
                root.showOsd();
            }
        }
    }

    Process {
        id: numlockProc
        command: ["bash", "-c", "hyprctl devices -j | python3 -c \"import sys,json; d=json.load(sys.stdin); print('1' if any(k.get('numLock') for k in d.get('keyboards',[])) else '0')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.osdType = "numlock";
                root.osdBool = this.text.trim() === "1";
                root.showOsd();
            }
        }
    }

    function showOsd() {
        osdVisible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: Config.osdHideTimeout
        onTriggered: root.osdVisible = false
    }

    function getColor(): string {
        if (osdType === "volume" && osdBool) return Theme.red;
        if (osdType === "capslock") return osdBool ? Theme.green : Theme.overlay0;
        if (osdType === "numlock") return osdBool ? Theme.green : Theme.overlay0;
        return Theme.blue;
    }

    function getLabel(): string {
        if (osdType === "volume") return osdBool ? "Muted" : Math.round(osdValue * 100) + "%";
        if (osdType === "brightness") return Math.round(osdValue * 100) + "%";
        if (osdType === "capslock") return osdBool ? "Caps Lock ON" : "Caps Lock OFF";
        if (osdType === "numlock") return osdBool ? "Num Lock ON" : "Num Lock OFF";
        return "";
    }

    property bool hasProgressBar: osdType === "volume" || osdType === "brightness"

    LazyLoader {
        id: osdLoader
        active: root.osdVisible

        PanelWindow {
            id: osdWindow

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osd"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Compact OSD pill
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.osdBottomMargin
                width: osdRow.implicitWidth + 28
                height: Config.osdHeight

                Rectangle {
                    id: osdBg
                    anchors.fill: parent
                    radius: Config.osdRadius
                    color: Theme.osdBg
                    border.color: Theme.surface1
                    border.width: 1
                }

                scale: Config.animOsdScaleFrom
                opacity: 0

                NumberAnimation on scale {
                    from: Config.animOsdScaleFrom; to: 1.0
                    duration: Config.animOsdScaleDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: Config.animOsdFadeDuration
                    easing.type: Easing.OutCubic
                    running: true
                }

                Row {
                    id: osdRow
                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16

                        // Volume icons
                        IconVolumeX {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "volume" && root.osdBool
                        }
                        IconVolume2 {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "volume" && !root.osdBool && root.osdValue > 0.66
                        }
                        IconVolume1 {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "volume" && !root.osdBool && root.osdValue > 0.33 && root.osdValue <= 0.66
                        }
                        IconVolume {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "volume" && !root.osdBool && root.osdValue <= 0.33
                        }

                        // Brightness icon
                        IconSun {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "brightness"
                        }

                        // Capslock icons
                        IconLock {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "capslock" && root.osdBool
                        }
                        IconLockOpen {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "capslock" && !root.osdBool
                        }

                        // Numlock icon
                        IconKeyboard {
                            anchors.centerIn: parent; size: 16; color: root.getColor()
                            visible: root.osdType === "numlock"
                        }
                    }

                    // Progress bar (volume/brightness)
                    Item {
                        visible: root.hasProgressBar
                        anchors.verticalCenter: parent.verticalCenter
                        width: Config.osdProgressWidth
                        height: Config.osdProgressHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: Theme.surface1
                        }

                        Rectangle {
                            width: parent.width * Math.min(root.osdValue, 1.0)
                            height: parent.height
                            radius: 2
                            color: root.osdType === "volume" && root.osdBool ? Theme.red : Theme.blue

                            Behavior on width {
                                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.getLabel()
                        color: Theme.subtext0
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
