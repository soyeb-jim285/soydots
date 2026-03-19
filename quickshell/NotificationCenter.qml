pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool visible: false
    required property var notifSource

    property bool clearingAll: false

    // Quick settings state
    property bool wifiEnabled: true
    property bool btEnabled: false
    property bool dndEnabled: false
    property bool nightLightEnabled: false
    property bool caffeineEnabled: false

    // Volume/brightness
    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    property real brightness: 0.5

    function toggle() {
        root.visible = !root.visible;
        if (root.visible) {
            notifSource.resetUnread();
            wifiProc.running = true;
            btProc.running = true;
            brightnessReadProc.running = true;
        }
    }

    function animatedClearAll() {
        clearingAll = true;
        clearAllTimer.restart();
    }

    Timer {
        id: clearAllTimer
        interval: 300
        onTriggered: {
            root.notifSource.clearAll();
            root.clearingAll = false;
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggle(); }
    }

    Timer {
        interval: 30000; running: root.visible; repeat: true
        onTriggered: historyList.forceLayout()
    }

    // Polling processes
    Process {
        id: wifiProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
    }
    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep Powered | awk '{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = this.text.trim() === "yes"
        }
    }
    Process {
        id: brightnessReadProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(",");
                if (parts.length >= 4) root.brightness = parseInt(parts[3]) / 100;
            }
        }
    }

    // Toggle processes
    Process { id: wifiOnProc; command: ["nmcli", "radio", "wifi", "on"]; onRunningChanged: if (!running) wifiProc.running = true }
    Process { id: wifiOffProc; command: ["nmcli", "radio", "wifi", "off"]; onRunningChanged: if (!running) wifiProc.running = true }
    Process { id: btOnProc; command: ["bluetoothctl", "power", "on"]; onRunningChanged: if (!running) btProc.running = true }
    Process { id: btOffProc; command: ["bluetoothctl", "power", "off"]; onRunningChanged: if (!running) btProc.running = true }
    Process { id: nightLightOnProc; command: ["bash", "-c", "pkill hyprsunset; hyprsunset -t 4000 &"] }
    Process { id: nightLightOffProc; command: ["pkill", "hyprsunset"] }
    Process { id: caffeineOnProc; command: ["bash", "-c", "pkill hypridle; notify-send 'Caffeine' 'Screen will stay awake'"] }
    Process { id: caffeineOffProc; command: ["bash", "-c", "hypridle & notify-send 'Caffeine' 'Screen sleep restored'"] }
    Process { id: lockProc; command: ["hyprlock"] }
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && hyprshot -m region --freeze --clipboard-only"] }

    // Brightness set
    Process {
        id: brightnessSetProc
        property int pct: 50
        command: ["brightnessctl", "set", pct + "%"]
    }

    LazyLoader {
        id: centerLoader
        active: root.visible

        PanelWindow {
            id: window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent; color: "#000000"; opacity: 0
                MouseArea { anchors.fill: parent; onClicked: root.toggle() }
                NumberAnimation on opacity {
                    from: 0; to: 0.4; duration: 200
                    easing.type: Easing.OutCubic; running: true
                }
            }

            Rectangle {
                id: panel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 6
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                width: 300
                color: Theme.mantle
                radius: 14
                border.color: Theme.surface1
                border.width: 1

                NumberAnimation on anchors.rightMargin {
                    from: -320; to: 8; duration: 300
                    easing.type: Easing.OutCubic; running: true
                }
                opacity: 1
                NumberAnimation on opacity {
                    from: 0; to: 1; duration: 200
                    easing.type: Easing.OutCubic; running: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: mainCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: mainCol
                        width: parent.width
                        spacing: 8

                        // ===== QUICK SETTINGS =====

                        // Toggle grid — 2x3
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 6
                            columnSpacing: 6

                            // Wi-Fi
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: root.wifiEnabled ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf1eb"
                                        color: root.wifiEnabled ? Theme.crust : Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Wi-Fi"
                                        color: root.wifiEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.wifiEnabled) wifiOffProc.running = true;
                                        else wifiOnProc.running = true;
                                        root.wifiEnabled = !root.wifiEnabled;
                                    }
                                }
                            }

                            // Bluetooth
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: root.btEnabled ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf293"
                                        color: root.btEnabled ? Theme.crust : Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Bluetooth"
                                        color: root.btEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.btEnabled) btOffProc.running = true;
                                        else btOnProc.running = true;
                                        root.btEnabled = !root.btEnabled;
                                    }
                                }
                            }

                            // Do Not Disturb
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: root.dndEnabled ? Theme.mauve : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf1f6"
                                        color: root.dndEnabled ? Theme.crust : Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "DND"
                                        color: root.dndEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dndEnabled = !root.dndEnabled
                                }
                            }

                            // Night Light
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: root.nightLightEnabled ? Theme.peach : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf186"
                                        color: root.nightLightEnabled ? Theme.crust : Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Night"
                                        color: root.nightLightEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.nightLightEnabled = !root.nightLightEnabled;
                                        if (root.nightLightEnabled) nightLightOnProc.running = true;
                                        else nightLightOffProc.running = true;
                                    }
                                }
                            }

                            // Screenshot
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: ssMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf030"
                                        color: Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Screenshot"
                                        color: Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: ssMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: { root.toggle(); ssProc.running = true; }
                                }
                            }

                            // Lock Screen
                            Rectangle {
                                Layout.fillWidth: true
                                height: 56; radius: 10
                                color: lockMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "\uf023"
                                        color: Theme.overlay0
                                        font.pixelSize: 16; font.family: Theme.iconFont
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Lock"
                                        color: Theme.subtext0
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: lockMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: { root.toggle(); lockProc.running = true; }
                                }
                            }
                        }

                        // ===== SLIDERS =====

                        // Volume slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.muted ? "\uf6a9" : "\uf028"
                                    color: root.muted ? Theme.red : Theme.blue
                                    font.pixelSize: 12; font.family: Theme.iconFont

                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted; }
                                    }
                                }
                                Text {
                                    text: "Volume"
                                    color: Theme.subtext0
                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(root.volume * 100) + "%"
                                    color: Theme.overlay0
                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                }
                            }

                            // Slider track
                            Item {
                                Layout.fillWidth: true
                                height: 20

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width; height: 4; radius: 2
                                    color: Theme.surface1
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * Math.min(root.volume, 1.0)
                                    height: 4; radius: 2
                                    color: root.muted ? Theme.red : Theme.blue
                                    Behavior on width { NumberAnimation { duration: 50 } }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: parent.width * Math.min(root.volume, 1.0) - 6
                                    width: 12; height: 12; radius: 6
                                    color: root.muted ? Theme.red : Theme.blue
                                    Behavior on x { NumberAnimation { duration: 50 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (event) => {
                                        if (root.sink?.audio)
                                            root.sink.audio.volume = Math.max(0, Math.min(1, event.x / width));
                                    }
                                    onPositionChanged: (event) => {
                                        if (pressed && root.sink?.audio)
                                            root.sink.audio.volume = Math.max(0, Math.min(1, event.x / width));
                                    }
                                }
                            }
                        }

                        // Brightness slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "\uf185"
                                    color: Theme.yellow
                                    font.pixelSize: 12; font.family: Theme.iconFont
                                }
                                Text {
                                    text: "Brightness"
                                    color: Theme.subtext0
                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(root.brightness * 100) + "%"
                                    color: Theme.overlay0
                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                height: 20

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width; height: 4; radius: 2
                                    color: Theme.surface1
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * root.brightness
                                    height: 4; radius: 2
                                    color: Theme.yellow
                                    Behavior on width { NumberAnimation { duration: 50 } }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: parent.width * root.brightness - 6
                                    width: 12; height: 12; radius: 6
                                    color: Theme.yellow
                                    Behavior on x { NumberAnimation { duration: 50 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (event) => {
                                        root.brightness = Math.max(0.01, Math.min(1, event.x / width));
                                        brightnessSetProc.pct = Math.round(root.brightness * 100);
                                        brightnessSetProc.running = true;
                                    }
                                    onPositionChanged: (event) => {
                                        if (pressed) {
                                            root.brightness = Math.max(0.01, Math.min(1, event.x / width));
                                            brightnessSetProc.pct = Math.round(root.brightness * 100);
                                            brightnessSetProc.running = true;
                                        }
                                    }
                                }
                            }
                        }

                        // ===== SEPARATOR =====
                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: Theme.surface0
                        }

                        // ===== NOTIFICATIONS HEADER =====
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "\uf0f3"
                                color: Theme.blue
                                font.pixelSize: 13
                                font.family: Theme.iconFont
                            }
                            Text {
                                text: "Notifications"
                                color: Theme.text
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: root.notifSource.history.length > 0
                                text: root.notifSource.history.length
                                color: Theme.overlay0
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                            }
                            Rectangle {
                                visible: root.notifSource.history.length > 0
                                width: 22; height: 22; radius: 11
                                color: clearMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf1f8"
                                    color: clearMouse.containsMouse ? Theme.red : Theme.overlay0
                                    font.pixelSize: 10; font.family: Theme.iconFont
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    id: clearMouse; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.animatedClearAll()
                                }
                            }
                        }

                        // ===== EMPTY STATE =====
                        Item {
                            visible: root.notifSource.history.length === 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            Column {
                                anchors.centerIn: parent; spacing: 6
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "\uf0f3"
                                    color: Theme.surface2
                                    font.pixelSize: 24; font.family: Theme.iconFont
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "All clear"
                                    color: Theme.overlay0
                                    font.pixelSize: 11; font.family: Theme.fontFamily
                                }
                            }
                        }

                        // ===== NOTIFICATION LIST =====
                        Repeater {
                            model: root.notifSource.history

                            Rectangle {
                                id: histItem
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                height: histRow.implicitHeight + 12
                                radius: 8
                                color: histMouse.containsMouse ? Theme.surface0 : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                property bool dying: false
                                property bool gone: dying || root.clearingAll
                                x: gone ? width : 0
                                opacity: gone ? 0 : 1
                                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                function dismiss() {
                                    dying = true;
                                    dismissTimer.restart();
                                }
                                Timer {
                                    id: dismissTimer
                                    interval: 300
                                    onTriggered: root.notifSource.dismissHistory(histItem.index)
                                }

                                Row {
                                    id: histRow
                                    anchors.left: parent.left
                                    anchors.right: histDismiss.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6; height: 6; radius: 3
                                        color: root.notifSource.urgencyColor(histItem.modelData.urgency)
                                    }

                                    Column {
                                        width: parent.width - 18
                                        spacing: 1

                                        Row {
                                            width: parent.width; spacing: 4
                                            Text {
                                                text: histItem.modelData.summary || histItem.modelData.appName || "Notification"
                                                color: Theme.text
                                                font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                                                elide: Text.ElideRight
                                                width: parent.width - timeText.implicitWidth - 8
                                            }
                                            Text {
                                                id: timeText
                                                text: root.notifSource.timeAgo(histItem.modelData.time)
                                                color: Theme.surface2
                                                font.pixelSize: 9; font.family: Theme.fontFamily
                                            }
                                        }

                                        Text {
                                            visible: text !== ""
                                            text: histItem.modelData.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                                            color: Theme.subtext0
                                            font.pixelSize: 10; font.family: Theme.fontFamily
                                            width: parent.width
                                            elide: Text.ElideRight; maximumLineCount: 1
                                        }
                                    }
                                }

                                Rectangle {
                                    id: histDismiss
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 6
                                    width: 24; height: 24; radius: 12
                                    visible: histMouse.containsMouse || histDismissMouse.containsMouse
                                    color: histDismissMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00d"
                                        color: histDismissMouse.containsMouse ? Theme.red : Theme.overlay0
                                        font.pixelSize: 11; font.family: Theme.iconFont
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }
                                    MouseArea {
                                        id: histDismissMouse; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: histItem.dismiss()
                                    }
                                }

                                MouseArea {
                                    id: histMouse; anchors.fill: parent
                                    hoverEnabled: true; z: -1
                                }
                            }
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    onActivated: root.toggle()
                }
            }
        }
    }
}
