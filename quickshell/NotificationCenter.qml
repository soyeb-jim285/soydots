pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "icons"
import "quill" as Quill

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
        } else {
            panelHovered = false;
            closeTimer.stop();
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

    property bool panelHovered: false

    function show() {
        if (!root.visible) root.toggle();
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            if (!root.panelHovered && root.visible)
                root.toggle();
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggle(); }
        function show(): void { root.show(); }
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

    // Focus app window by searching hyprland clients
    Process {
        id: focusAppProc
        property string appName: ""
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = focusAppProc.appName.toLowerCase();
                try {
                    let clients = JSON.parse(this.text);
                    // Try matching class, initialClass, or title (case-insensitive)
                    let match = null;
                    for (let c of clients) {
                        let cls = (c["class"] || "").toLowerCase();
                        let initCls = (c.initialClass || "").toLowerCase();
                        let title = (c.title || "").toLowerCase();
                        if (cls === name || initCls === name) { match = c; break; }
                        if (cls.includes(name) || initCls.includes(name)) { match = c; break; }
                        if (title.includes(name)) { if (!match) match = c; }
                    }
                    if (match) {
                        Hyprland.dispatch("focuswindow address:" + match.address);
                    }
                } catch(e) {}
            }
        }
    }

    // Toggle processes
    Process { id: wifiOnProc; command: ["nmcli", "radio", "wifi", "on"]; onRunningChanged: if (!running) wifiProc.running = true }
    Process { id: wifiOffProc; command: ["nmcli", "radio", "wifi", "off"]; onRunningChanged: if (!running) wifiProc.running = true }
    Process { id: btOnProc; command: ["bluetoothctl", "power", "on"]; onRunningChanged: if (!running) btProc.running = true }
    Process { id: btOffProc; command: ["bluetoothctl", "power", "off"]; onRunningChanged: if (!running) btProc.running = true }
    Process { id: nightLightOnProc; command: ["bash", "-c", "pkill hyprsunset; hyprsunset -t " + Config.nightLightTemp + " &"] }
    Process { id: nightLightOffProc; command: ["pkill", "hyprsunset"] }
    Process { id: caffeineOnProc; command: ["bash", "-c", "systemctl --user stop hypridle; notify-send 'Caffeine' 'Screen will stay awake'"] }
    Process { id: caffeineOffProc; command: ["bash", "-c", "systemctl --user start hypridle; notify-send 'Caffeine' 'Screen sleep restored'"] }
    Process { id: lockProc; command: ["quickshell", "msg", "lockscreen", "lock"] }
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && ~/jimdots/hypr/screenshot.sh region"] }
    Process { id: reloadProc; command: ["hyprctl", "dispatch", "exec", "bash -c 'START=$(date +%s%N); hyprctl reload; killall quickshell; sleep 0.3; quickshell & sleep 0.5; systemctl --user restart hypridle quill-polkit-agent; END=$(date +%s%N); MS=$(( (END - START) / 1000000 )); notify-send Reload \"Reloaded in ${MS}ms\"'"] }
    Process { id: settingsOpenProc; command: ["quickshell", "msg", "settings", "toggle"] }
    Process { id: powerMenuProc; command: ["quickshell", "msg", "powermenu", "toggle"] }

    // Brightness set
    Process {
        id: brightnessSetProc
        property int pct: 50
        command: ["/home/jim/jimdots/hypr/brightness-sync.sh", "set", pct + "%"]
    }

    LazyLoader {
        id: centerLoader
        active: root.visible

        PanelWindow {
            id: window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-notifcenter"

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * 0.25)
                MouseArea { anchors.fill: parent; onClicked: root.toggle() }
                NumberAnimation on fadeIn {
                    from: 0; to: 1; duration: Config.animDuration
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
                width: Config.notifCenterWidth
                color: Theme.notifCenterBg
                radius: Config.notifCenterRadius
                border.color: Theme.surface1
                border.width: 1

                // Slide in from the right
                transform: Translate { id: panelSlide; x: Config.notifCenterWidth + 16 }
                NumberAnimation {
                    target: panelSlide; property: "x"
                    from: Config.notifCenterWidth + 16; to: 0; duration: 300
                    easing.type: Easing.OutCubic; running: true
                }
                opacity: 0
                NumberAnimation on opacity {
                    from: 0; to: 1; duration: 200
                    easing.type: Easing.OutCubic; running: true
                }

                HoverHandler {
                    id: panelHover
                    onHoveredChanged: {
                        root.panelHovered = hovered;
                        if (!hovered) closeTimer.restart();
                        else closeTimer.stop();
                    }
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
                            columns: Config.notifQsColumns
                            rowSpacing: Config.notifQsSpacing
                            columnSpacing: Config.notifQsSpacing

                            // Wi-Fi
                            Rectangle {
                                Layout.fillWidth: true
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: root.wifiEnabled ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconWifi {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: root.wifiEnabled ? Theme.crust : Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Wi-Fi"
                                        color: root.wifiEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
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
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: root.btEnabled ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconBluetooth {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: root.btEnabled ? Theme.crust : Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Bluetooth"
                                        color: root.btEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
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
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: root.dndEnabled ? Theme.mauve : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconBellOff {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: root.dndEnabled ? Theme.crust : Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "DND"
                                        color: root.dndEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
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
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: root.nightLightEnabled ? Theme.peach : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconMoon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: root.nightLightEnabled ? Theme.crust : Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Night"
                                        color: root.nightLightEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
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
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: ssMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconCamera {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Screenshot"
                                        color: Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: ssMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: { root.toggle(); ssProc.running = true; }
                                }
                            }

                            // Power Menu
                            Rectangle {
                                Layout.fillWidth: true
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: powerMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconPower {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Power"
                                        color: Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: powerMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: { root.toggle(); powerMenuProc.running = true; }
                                }
                            }

                            // Reload (Hyprland + Quickshell)
                            Rectangle {
                                Layout.fillWidth: true
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: reloadMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconRefreshCw {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Reload"
                                        color: Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: reloadMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: reloadProc.running = true
                                }
                            }

                            // Caffeine
                            Rectangle {
                                Layout.fillWidth: true
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: root.caffeineEnabled ? Theme.yellow : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconCoffee {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: root.caffeineEnabled ? Theme.crust : Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Caffeine"
                                        color: root.caffeineEnabled ? Theme.crust : Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.caffeineEnabled = !root.caffeineEnabled;
                                        if (root.caffeineEnabled) caffeineOnProc.running = true;
                                        else caffeineOffProc.running = true;
                                    }
                                }
                            }

                            // Settings
                            Rectangle {
                                Layout.fillWidth: true
                                height: Config.notifQsButtonHeight; radius: Config.notifQsButtonRadius
                                color: settingsMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    IconSettings {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        size: Config.notifQsIconSize
                                        color: Theme.overlay0
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Settings"
                                        color: Theme.subtext0
                                        font.pixelSize: Config.notifQsLabelSize; font.family: Theme.fontFamily
                                    }
                                }
                                MouseArea {
                                    id: settingsMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: { root.toggle(); settingsOpenProc.running = true; }
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
                                Item {
                                    width: 12; height: 12
                                    IconVolume2 {
                                        anchors.centerIn: parent
                                        size: 12
                                        color: Theme.blue
                                        visible: !root.muted
                                    }
                                    IconVolumeX {
                                        anchors.centerIn: parent
                                        size: 12
                                        color: Theme.red
                                        visible: root.muted
                                    }

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

                            Quill.Slider {
                                Layout.fillWidth: true
                                value: Math.round(root.volume * 100)
                                from: 0; to: 100; stepSize: 1
                                trackColor: root.muted ? Theme.red : Theme.blue
                                onMoved: (val) => {
                                    if (root.sink?.audio)
                                        root.sink.audio.volume = val / 100;
                                }
                            }
                        }

                        // Brightness slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                IconSun {
                                    size: 12
                                    color: Theme.yellow
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

                            Quill.Slider {
                                Layout.fillWidth: true
                                value: Math.round(root.brightness * 100)
                                from: 0; to: 100; stepSize: 1
                                trackColor: Theme.yellow
                                onMoved: (val) => {
                                    root.brightness = val / 100;
                                    brightnessSetProc.pct = Math.round(val);
                                    brightnessSetProc.running = true;
                                }
                            }
                        }

                        // ===== SEPARATOR =====
                        Quill.Separator { Layout.fillWidth: true }

                        // ===== NOTIFICATIONS HEADER =====
                        RowLayout {
                            Layout.fillWidth: true

                            IconBell {
                                size: 13
                                color: Theme.blue
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
                                IconTrash {
                                    anchors.centerIn: parent
                                    size: 10
                                    color: clearMouse.containsMouse ? Theme.red : Theme.overlay0
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
                                IconBell {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    size: 24
                                    color: Theme.surface2
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
                                implicitHeight: histCol.implicitHeight + 16
                                Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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

                                // Right side: time or dismiss button
                                Item {
                                    id: histRight
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 8
                                    width: Math.max(timeText.implicitWidth, 22)
                                    height: 22

                                    property bool hovered: histMouse.containsMouse || histDismissMouse.containsMouse

                                    Text {
                                        id: timeText
                                        anchors.centerIn: parent
                                        text: root.notifSource.timeAgo(histItem.modelData.time)
                                        color: Theme.surface2
                                        font.pixelSize: 9; font.family: Theme.fontFamily
                                        opacity: histRight.hovered ? 0 : 1
                                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }

                                    Rectangle {
                                        id: histDismiss
                                        anchors.centerIn: parent
                                        width: 22; height: 22; radius: 11
                                        opacity: histRight.hovered ? 1 : 0
                                        visible: opacity > 0
                                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        color: histDismissMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                        IconX {
                                            anchors.centerIn: parent
                                            size: 10
                                            color: histDismissMouse.containsMouse ? Theme.red : Theme.overlay0
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        MouseArea {
                                            id: histDismissMouse; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: histItem.dismiss()
                                        }
                                    }
                                }

                                // Left side: icon + text content + action buttons
                                Column {
                                    id: histCol
                                    anchors.left: parent.left
                                    anchors.right: histRight.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 4

                                    Row {
                                        id: histRow
                                        width: parent.width
                                        spacing: 8

                                    // Icon/image slot with urgency dot fallback
                                    Item {
                                        id: histIconSlot
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: histIconHasImage ? 28 : 6
                                        height: histIconHasImage ? 28 : 6

                                        function resolveIcon(src) {
                                            if (src === "") return "";
                                            if (src.startsWith("image://icon/"))
                                                return "file://" + src.substring("image://icon/".length);
                                            if (src.startsWith("file://"))
                                                return src;
                                            if (src.startsWith("/"))
                                                return "file://" + src;
                                            return Quickshell.iconPath(src, true);
                                        }
                                        property string iconSource: {
                                            let md = histItem.modelData;
                                            if ((md.image || "") !== "") {
                                                let resolved = resolveIcon(md.image);
                                                if (resolved !== "") return resolved;
                                            }
                                            let icon = (md.appIcon || "") !== "" ? md.appIcon : (md.appName || "");
                                            return resolveIcon(icon);
                                        }
                                        property bool iconError: false
                                        property bool histIconHasImage: iconSource !== "" && !iconError

                                        // App icon / notification image
                                        Rectangle {
                                            visible: histIconSlot.histIconHasImage
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.crust
                                            border.color: Theme.surface1
                                            border.width: 1
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 1
                                                source: histIconSlot.iconSource
                                                sourceSize.width: 28
                                                sourceSize.height: 28
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                                asynchronous: true
                                                onStatusChanged: {
                                                    if (status === Image.Error)
                                                        histIconSlot.iconError = true;
                                                }
                                            }
                                        }

                                        // Urgency dot fallback
                                        Rectangle {
                                            visible: !histIconSlot.histIconHasImage
                                            anchors.centerIn: parent
                                            width: 6; height: 6; radius: 3
                                            color: root.notifSource.urgencyColor(histItem.modelData.urgency)
                                        }
                                    }

                                    Column {
                                        width: parent.width - histIconSlot.width - 8
                                        spacing: 1

                                        Text {
                                            text: histItem.modelData.summary || histItem.modelData.appName || "Notification"
                                            color: Theme.text
                                            font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
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

                                    // Action buttons (hover reveal)
                                    Row {
                                        visible: histMouse.containsMouse && histItem.modelData.actions && histItem.modelData.actions.length > 0
                                        width: parent.width
                                        spacing: 6

                                        Repeater {
                                            model: {
                                                let acts = histItem.modelData.actions;
                                                if (!acts) return [];
                                                let result = [];
                                                for (let i = 0; i < Math.min(acts.length, 3); i++)
                                                    result.push({ text: acts[i].text, idx: i });
                                                return result;
                                            }

                                            Rectangle {
                                                required property var modelData
                                                required property int index
                                                property int actionCount: {
                                                    let acts = histItem.modelData.actions;
                                                    return acts ? Math.min(acts.length, 3) : 0;
                                                }
                                                width: actionCount > 0 ? ((parent?.width ?? 0) - (actionCount - 1) * 6) / actionCount : (parent?.width ?? 0)
                                                height: 22
                                                radius: 6
                                                color: histActionMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                                Behavior on color { ColorAnimation { duration: 80 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.text
                                                    color: histActionMouse.containsMouse ? Theme.text : Theme.subtext0
                                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                                    Behavior on color { ColorAnimation { duration: 80 } }
                                                }

                                                MouseArea {
                                                    id: histActionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let acts = histItem.modelData.actions;
                                                        if (acts && acts.length > modelData.idx)
                                                            acts[modelData.idx].invoke();
                                                        histItem.dismiss();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: histMouse; anchors.fill: parent
                                    hoverEnabled: true; z: -1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // Invoke default action if available
                                        let md = histItem.modelData;
                                        if (md.notif && md.actions && md.actions.length > 0)
                                            md.actions[0].invoke();
                                        // Focus the app's window (searches clients by class/title)
                                        if (md.appName !== "") {
                                            focusAppProc.appName = md.appName;
                                            focusAppProc.running = true;
                                        }
                                        root.toggle();
                                    }
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
