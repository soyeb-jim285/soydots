pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "bar"

Scope {
    id: root

    property string activePopup: ""
    property bool clockOpen: activePopup === "clock"
    property bool wifiOpen: activePopup === "wifi"
    property bool btOpen: activePopup === "bluetooth"
    property int notifUnreadCount: 0
    property string lastPopup: ""

    onActivePopupChanged: {
        if (activePopup !== "") lastPopup = activePopup;
    }

    // Calendar state
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property int viewMonth: currentMonth
    property int viewYear: currentYear
    property int today: new Date().getDate()
    property var monthNames: ["January", "February", "March", "April", "May", "June",
                               "July", "August", "September", "October", "November", "December"]
    property var dayHeaders: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    property string uptimeText: ""

    function daysInMonth(month: int, year: int): int {
        return new Date(year, month + 1, 0).getDate();
    }
    function firstDayOfWeek(month: int, year: int): int {
        return new Date(year, month, 1).getDay();
    }
    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; }
        else { viewMonth--; }
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; }
        else { viewMonth++; }
    }
    property var calendarDays: {
        let days = [];
        let totalDays = daysInMonth(viewMonth, viewYear);
        let startDay = firstDayOfWeek(viewMonth, viewYear);
        let prevDays = viewMonth === 0 ? daysInMonth(11, viewYear - 1) : daysInMonth(viewMonth - 1, viewYear);
        for (let i = startDay - 1; i >= 0; i--)
            days.push({ day: prevDays - i, current: false });
        for (let d = 1; d <= totalDays; d++)
            days.push({ day: d, current: true });
        let remaining = 42 - days.length;
        for (let i = 1; i <= remaining; i++)
            days.push({ day: i, current: false });
        return days;
    }

    // WiFi state
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiPasswordSSID: ""
    property string wifiError: ""
    property string wifiConnectingSSID: ""
    property bool wifiJustClosed: false

    // Bluetooth state (using Quickshell.Bluetooth native API)
    property var btAdapter: Bluetooth.defaultAdapter
    property bool btPowered: btAdapter?.enabled ?? false
    property bool btScanning: btAdapter?.discovering ?? false
    property bool btJustClosed: false

    // Auto-stop BT scanning after 60 seconds
    Timer {
        id: btScanTimeout
        interval: Config.btScanTimeout
        onTriggered: {
            if (root.btAdapter && root.btScanning)
                root.btAdapter.discovering = false;
        }
    }
    onBtScanningChanged: {
        if (btScanning) btScanTimeout.restart();
        else btScanTimeout.stop();
    }

    function togglePopup(name: string) {
        if (root.activePopup === name) {
            root.activePopup = "";
            if (name === "wifi") {
                root.wifiPasswordSSID = "";
                root.wifiError = "";
                root.wifiConnectingSSID = "";
                root.wifiJustClosed = true;
                justClosedTimer.restart();
            }
            if (name === "bluetooth") {
                root.btJustClosed = true;
                btJustClosedTimer.restart();
                // Stop scanning when panel closes
                if (root.btAdapter && root.btAdapter.discovering)
                    root.btAdapter.discovering = false;
            }
        } else {
            root.activePopup = name;
            root.wifiJustClosed = false;
            root.btJustClosed = false;
            if (name === "clock") {
                viewMonth = currentMonth;
                viewYear = currentYear;
                uptimeProc.running = true;
            }
            if (name === "wifi") {
                wifiScanProc.running = true;
                root.wifiError = "";
                root.wifiPasswordSSID = "";
            }
            if (name === "bluetooth") {
                // Start scanning when panel opens
                if (root.btAdapter && root.btPowered && !root.btScanning)
                    root.btAdapter.discovering = true;
            }
        }
    }

    function submitWifiPassword() {
        if (wifiPassInput.text.length > 0) {
            wifiConnectNewProc.ssid = root.wifiPasswordSSID;
            wifiConnectNewProc.password = wifiPassInput.text;
            wifiConnectNewProc.running = true;
            wifiPassInput.text = "";
        }
    }

    Timer {
        id: justClosedTimer
        interval: 300
        onTriggered: root.wifiJustClosed = false
    }
    Timer {
        id: btJustClosedTimer
        interval: 300
        onTriggered: root.btJustClosed = false
    }

    onWifiPasswordSSIDChanged: {
        if (wifiPasswordSSID !== "") focusTimer.restart();
    }
    Timer {
        id: focusTimer
        interval: 100
        onTriggered: wifiPassInput.forceActiveFocus()
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = this.text.trim().replace("up ", "")
        }
    }

    // WiFi processes
    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        onRunningChanged: if (running) root.wifiScanning = true
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiScanning = false;
                let lines = this.text.trim().split("\n");
                let networks = [];
                let seen = {};
                for (let line of lines) {
                    if (line.trim() === "") continue;
                    let parts = line.split(":");
                    if (parts.length >= 4 && parts[0] !== "") {
                        let ssid = parts[0];
                        if (seen[ssid]) continue;
                        seen[ssid] = true;
                        networks.push({
                            ssid: ssid,
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2],
                            active: parts[3] === "*"
                        });
                    }
                }
                networks.sort((a, b) => {
                    if (a.active && !b.active) return -1;
                    if (!a.active && b.active) return 1;
                    return b.signal - a.signal;
                });
                root.wifiNetworks = networks;
            }
        }
    }

    Process {
        id: wifiRescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onRunningChanged: {
            if (running) root.wifiScanning = true;
        }
    }
    Timer {
        id: rescanDelay
        interval: Config.wifiRescanDelay
        onTriggered: wifiScanProc.running = true
    }

    Process {
        id: wifiConnectProc
        property string ssid: ""
        command: ["nmcli", "device", "wifi", "connect", ssid]
        onRunningChanged: {
            if (running) {
                root.wifiConnectingSSID = ssid;
                root.wifiError = "";
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiConnectingSSID = "";
                if (this.text.includes("successfully")) {
                    root.wifiError = "";
                    wifiScanProc.running = true;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                let err = this.text.trim();
                if (err !== "") {
                    root.wifiConnectingSSID = "";
                    let needsPassword = false;
                    for (let i = 0; i < root.wifiNetworks.length; i++) {
                        let net = root.wifiNetworks[i];
                        if (net.ssid === wifiConnectProc.ssid && net.security !== "" && net.security !== "--") {
                            needsPassword = true;
                            break;
                        }
                    }
                    if (needsPassword) {
                        root.wifiPasswordSSID = wifiConnectProc.ssid;
                        root.wifiError = "";
                    } else {
                        root.wifiError = err;
                    }
                }
            }
        }
    }

    Process {
        id: wifiConnectNewProc
        property string ssid: ""
        property string password: ""
        command: ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        onRunningChanged: {
            if (running) {
                root.wifiConnectingSSID = ssid;
                root.wifiError = "";
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiConnectingSSID = "";
                root.wifiPasswordSSID = "";
                root.wifiError = "";
                wifiScanProc.running = true;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                let err = this.text.trim();
                if (err !== "") {
                    root.wifiConnectingSSID = "";
                    root.wifiError = err;
                }
            }
        }
    }


    Process {
        id: wifiDisconnectProc
        command: ["bash", "-c", "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE device status | grep wifi | head -1 | cut -d: -f1)"]
        stdout: StdioCollector {
            onStreamFinished: wifiScanProc.running = true
        }
    }

    // ===== SINGLE WINDOW for bar + panels =====
    PanelWindow {
        id: mainWindow

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 500
        exclusiveZone: Theme.barHeight
        color: "transparent"

        // WiFi panel positioning
        property real wifiPanelWidth: Config.wifiPanelWidth
        property real wifiIconWindowX: barContent.x + rightSection.x + networkWidget.x + networkWidget.width / 2
        property real wifiPanelLeft: {
            let left = wifiIconWindowX - wifiPanelWidth / 2;
            return Math.max(Theme.barMargin + 2 * Theme.barRadius,
                            Math.min(left, width - wifiPanelWidth - Theme.barMargin - 2 * Theme.barRadius));
        }

        // Bluetooth panel positioning
        property real btPanelWidth: Config.btPanelWidth
        property real btIconWindowX: barContent.x + rightSection.x + btWidget.x + btWidget.width / 2
        property real btPanelLeft: {
            let left = btIconWindowX - btPanelWidth / 2;
            return Math.max(Theme.barMargin + 2 * Theme.barRadius,
                            Math.min(left, width - btPanelWidth - Theme.barMargin - 2 * Theme.barRadius));
        }

        mask: Region {
            // Bar area — full width
            x: 0; y: 0
            width: mainWindow.width
            height: Theme.barHeight

            Region { item: panelHover; intersection: Intersection.Combine }
            Region { item: wifiPanelHover; intersection: Intersection.Combine }
            Region { item: btPanelHover; intersection: Intersection.Combine }
        }

        property real panelAnimHeight: root.clockOpen ? calendarContent.implicitHeight + 28
            : root.wifiOpen ? wifiContent.implicitHeight + 28
            : root.btOpen ? btContent.implicitHeight + 28
            : 0
        Behavior on panelAnimHeight {
            NumberAnimation { duration: Config.animPanelDuration; easing.type: Easing.OutCubic }
        }

        // ===== CALENDAR HOVER ZONE =====
        MouseArea {
            id: panelHover
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            z: 10
            width: Config.calendarWidth + Theme.barRadius * 2
            height: root.clockOpen ? Theme.barHeight + mainWindow.panelAnimHeight : Theme.barHeight
            hoverEnabled: true

            onMouseXChanged: checkHover()
            onMouseYChanged: checkHover()

            function checkHover() {
                let cx = clockContent.mapToItem(panelHover, 0, 0);
                if (mouseY <= Theme.barHeight && mouseX >= cx.x && mouseX <= cx.x + clockContent.width && !root.clockOpen) {
                    root.togglePopup("clock");
                }
            }

            onContainsMouseChanged: {
                if (containsMouse) {
                    closeTimer.stop();
                } else if (root.clockOpen) {
                    closeTimer.restart();
                }
            }

            // Calendar content
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barHeight
                width: Config.calendarWidth
                height: Math.max(0, mainWindow.panelAnimHeight)
                clip: true
                visible: root.clockOpen || (root.activePopup === "" && root.lastPopup === "clock")

                ColumnLayout {
                    id: calendarContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    width: 256
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: prevMouse.pressed ? Theme.surface1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "\uf053"; color: Theme.subtext0
                                font.pixelSize: 12; font.family: Theme.iconFont
                            }
                            MouseArea {
                                id: prevMouse; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.prevMonth()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.monthNames[root.viewMonth] + " " + root.viewYear
                            color: Theme.blue; font.pixelSize: 14
                            font.family: Theme.fontFamily; font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: nextMouse.pressed ? Theme.surface1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "\uf054"; color: Theme.subtext0
                                font.pixelSize: 12; font.family: Theme.iconFont
                            }
                            MouseArea {
                                id: nextMouse; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nextMonth()
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter; spacing: 0
                        Repeater {
                            model: root.dayHeaders
                            Text { required property string modelData; width: Config.calendarCellWidth; text: modelData; color: Theme.overlay0; font.pixelSize: 10; font.family: Theme.fontFamily; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    Grid {
                        Layout.alignment: Qt.AlignHCenter; columns: 7; spacing: 0
                        Repeater {
                            model: root.calendarDays
                            Rectangle {
                                required property var modelData; required property int index
                                property bool isToday: modelData.current && modelData.day === root.today && root.viewMonth === root.currentMonth && root.viewYear === root.currentYear
                                width: Config.calendarCellWidth; height: Config.calendarCellHeight; radius: Config.calendarCellRadius
                                color: isToday ? Theme.blue : "transparent"
                                Text { anchors.centerIn: parent; text: parent.modelData.day; color: parent.isToday ? Theme.crust : parent.modelData.current ? Theme.text : Theme.surface2; font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: parent.isToday }
                            }
                        }
                    }
                }
            }
        }

        // ===== WIFI PANEL HOVER ZONE =====
        MouseArea {
            id: wifiPanelHover
            x: mainWindow.wifiPanelLeft - Theme.barRadius
            y: Theme.barHeight
            z: 10
            width: mainWindow.wifiPanelWidth + Theme.barRadius * 2
            height: root.wifiOpen ? mainWindow.panelAnimHeight : 0
            hoverEnabled: true

            onContainsMouseChanged: {
                if (containsMouse) closeTimer.stop();
                else if (root.wifiOpen) closeTimer.restart();
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                width: mainWindow.wifiPanelWidth
                height: Math.max(0, mainWindow.panelAnimHeight)
                clip: true
                visible: root.wifiOpen || (root.activePopup === "" && root.lastPopup === "wifi")

                ColumnLayout {
                    id: wifiContent
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Wi-Fi"
                            color: Theme.text
                            font.pixelSize: 14; font.family: Theme.fontFamily; font.bold: true
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: rescanMouse.containsMouse ? Theme.surface1 : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                id: rescanIcon
                                anchors.centerIn: parent
                                text: "\uf2f1"
                                color: root.wifiScanning ? Theme.blue : Theme.subtext0
                                font.pixelSize: 12; font.family: Theme.iconFont
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            RotationAnimator {
                                target: rescanIcon
                                from: 0; to: 360; duration: 1000
                                loops: Animation.Infinite; running: root.wifiScanning
                            }
                            MouseArea {
                                id: rescanMouse; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { wifiRescanProc.running = true; rescanDelay.restart(); }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1 }

                    Text {
                        visible: root.wifiNetworks.length === 0
                        text: root.wifiScanning ? "Scanning..." : "No networks found"
                        color: Theme.subtext0; font.pixelSize: 12; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; Layout.bottomMargin: 8
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, Config.wifiMaxListHeight)
                        contentHeight: networkCol.implicitHeight
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        visible: root.wifiNetworks.length > 0

                        ColumnLayout {
                            id: networkCol; width: parent.width; spacing: 4
                            Repeater {
                                model: root.wifiNetworks
                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true; height: Config.wifiItemHeight; radius: Config.wifiItemRadius
                                    property bool isConnecting: root.wifiConnectingSSID === modelData.ssid
                                    color: netItemMouse.containsMouse ? Theme.surface0 : modelData.active ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.08) : "transparent"
                                    border.color: modelData.active ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.3) : "transparent"
                                    border.width: modelData.active ? 1 : 0
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                                        // Signal strength icon (static, no spin)
                                        Rectangle {
                                            width: 28; height: 28; radius: 14
                                            color: modelData.active ? Theme.blue : Theme.surface0
                                            Behavior on color { ColorAnimation { duration: 200 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf1eb"
                                                color: modelData.active ? Theme.crust : modelData.signal > 66 ? Theme.text : modelData.signal > 33 ? Theme.yellow : Theme.red
                                                font.pixelSize: 12; font.family: Theme.iconFont
                                                opacity: modelData.active ? 1 : Math.max(0.4, modelData.signal / 100)
                                            }
                                        }

                                        // Name + status
                                        Column {
                                            Layout.fillWidth: true; spacing: 1
                                            Text {
                                                text: modelData.ssid
                                                color: modelData.active ? Theme.blue : Theme.text
                                                font.pixelSize: 12; font.family: Theme.fontFamily
                                                font.bold: modelData.active
                                                elide: Text.ElideRight; width: parent.width
                                            }
                                            Text {
                                                text: isConnecting ? "Connecting..." : modelData.active ? "Connected \u2022 " + modelData.signal + "%" : modelData.security !== "" && modelData.security !== "--" ? "Secured" : "Open"
                                                color: isConnecting ? Theme.blue : modelData.active ? Theme.green : Theme.overlay0
                                                font.pixelSize: 9; font.family: Theme.fontFamily
                                            }
                                        }

                                        // Connect/disconnect action button
                                        Rectangle {
                                            id: wifiActionBtn
                                            width: 28; height: 28; radius: 14
                                            color: wifiActionMouse.containsMouse ? (modelData.active ? Theme.red : Theme.blue) : Theme.surface0
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            visible: !isConnecting

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.active ? "\uf127" : "\uf0c1"
                                                color: wifiActionMouse.containsMouse ? Theme.crust : Theme.subtext0
                                                font.pixelSize: 10; font.family: Theme.iconFont
                                            }

                                            MouseArea {
                                                id: wifiActionMouse; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.active) {
                                                        wifiDisconnectProc.running = true;
                                                    } else {
                                                        wifiConnectProc.ssid = modelData.ssid;
                                                        wifiConnectProc.running = true;
                                                    }
                                                }
                                            }
                                        }

                                        // Connecting spinner
                                        Item {
                                            id: wifiSpinner
                                            width: 28; height: 28
                                            visible: isConnecting
                                            property real sweep: 30
                                            property real tailProgress: 0
                                            property real cycleBase: 0

                                            Item {
                                                anchors.centerIn: parent
                                                width: 28; height: 28
                                                RotationAnimator on rotation { from: 0; to: 360; duration: 750; loops: Animation.Infinite; running: isConnecting }

                                                Shape {
                                                    anchors.fill: parent
                                                    ShapePath {
                                                        strokeColor: Theme.blue; strokeWidth: 2
                                                        fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                                        PathAngleArc {
                                                            centerX: 14; centerY: 14; radiusX: 12; radiusY: 12
                                                            startAngle: wifiSpinner.cycleBase + wifiSpinner.tailProgress * 270 - 90
                                                            sweepAngle: wifiSpinner.sweep
                                                        }
                                                    }
                                                }
                                            }

                                            SequentialAnimation {
                                                loops: Animation.Infinite; running: isConnecting
                                                ParallelAnimation {
                                                    NumberAnimation { target: wifiSpinner; property: "sweep"; from: 30; to: 300; duration: 525; easing.type: Easing.InOutCubic }
                                                    NumberAnimation { target: wifiSpinner; property: "tailProgress"; from: 0; to: 0; duration: 525 }
                                                }
                                                ParallelAnimation {
                                                    NumberAnimation { target: wifiSpinner; property: "sweep"; from: 300; to: 30; duration: 975; easing.type: Easing.InOutCubic }
                                                    NumberAnimation { target: wifiSpinner; property: "tailProgress"; from: 0; to: 1; duration: 975; easing.type: Easing.InOutCubic }
                                                }
                                                ScriptAction { script: { wifiSpinner.cycleBase += 270; wifiSpinner.tailProgress = 0; } }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf0c1"
                                                color: Theme.blue
                                                font.pixelSize: 10; font.family: Theme.iconFont
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: netItemMouse; anchors.fill: parent; hoverEnabled: true; z: -1
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.wifiPasswordSSID !== ""
                        Layout.fillWidth: true; spacing: 4
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1 }
                        Text { text: "Password for " + root.wifiPasswordSSID; color: Theme.subtext0; font.pixelSize: 11; font.family: Theme.fontFamily }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 4
                            Rectangle {
                                Layout.fillWidth: true; height: 30; radius: 6
                                color: Theme.surface0; border.color: wifiPassInput.activeFocus ? Theme.blue : Theme.surface1; border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                TextInput {
                                    id: wifiPassInput; anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter; color: Theme.text
                                    font.pixelSize: 12; font.family: Theme.fontFamily; echoMode: TextInput.Password; clip: true
                                    onAccepted: root.submitWifiPassword()
                                }
                            }
                            Rectangle {
                                width: 30; height: 30; radius: 6
                                color: connectBtnMouse.containsMouse ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "\uf054"; color: Theme.text; font.pixelSize: 12; font.family: Theme.iconFont }
                                MouseArea { id: connectBtnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.submitWifiPassword() }
                            }
                        }
                    }

                    Text { visible: root.wifiError !== ""; text: root.wifiError; color: Theme.red; font.pixelSize: 10; font.family: Theme.fontFamily; Layout.fillWidth: true; wrapMode: Text.Wrap }
                    Item { height: 4; Layout.fillWidth: true }
                }
            }
        }

        // ===== BLUETOOTH PANEL HOVER ZONE =====
        MouseArea {
            id: btPanelHover
            x: mainWindow.btPanelLeft - Theme.barRadius
            y: Theme.barHeight
            z: 10
            width: mainWindow.btPanelWidth + Theme.barRadius * 2
            height: root.btOpen ? mainWindow.panelAnimHeight : 0
            hoverEnabled: true

            onContainsMouseChanged: {
                if (containsMouse) closeTimer.stop();
                else if (root.btOpen) closeTimer.restart();
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                width: mainWindow.btPanelWidth
                height: Math.max(0, mainWindow.panelAnimHeight)
                clip: true
                visible: root.btOpen || (root.activePopup === "" && root.lastPopup === "bluetooth")

                ColumnLayout {
                    id: btContent
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    spacing: 6

                    // Header: title + power toggle
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Bluetooth"
                            color: Theme.text
                            font.pixelSize: 14; font.family: Theme.fontFamily; font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 40; height: 22; radius: 11
                            color: root.btPowered ? Theme.blue : Theme.surface1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 18; height: 18; radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.btPowered ? parent.width - width - 2 : 2
                                color: Theme.text
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.btAdapter)
                                        root.btAdapter.enabled = !root.btPowered;
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1 }

                    // Off state
                    Text {
                        visible: !root.btPowered
                        text: "Bluetooth is off"
                        color: Theme.subtext0; font.pixelSize: 12; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; Layout.bottomMargin: 8
                    }

                    // Device count for display logic
                    property int btDeviceCount: Bluetooth.devices.values.length

                    // Empty/scanning state
                    Text {
                        visible: root.btPowered && btContent.btDeviceCount === 0 && !root.btScanning
                        text: "No devices found"
                        color: Theme.subtext0; font.pixelSize: 12; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; Layout.bottomMargin: 8
                    }

                    // Device list (reactive from Bluetooth.devices model)
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, Config.btMaxListHeight)
                        contentHeight: btDevCol.implicitHeight
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        visible: root.btPowered && btContent.btDeviceCount > 0

                        ColumnLayout {
                            id: btDevCol; width: parent.width; spacing: 4

                            Repeater {
                                model: Bluetooth.devices

                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: showDevice ? Config.btDeviceHeight : 0; radius: Config.btDeviceRadius
                                    visible: showDevice
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    property bool showDevice: modelData.name !== "" && modelData.name !== modelData.address
                                    property bool isConnecting: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                                    color: btDevMouse.containsMouse ? Theme.surface0 : modelData.connected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.08) : "transparent"
                                    border.color: modelData.connected ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.3) : "transparent"
                                    border.width: modelData.connected ? 1 : 0

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                                        // BT icon (static, no spin)
                                        Rectangle {
                                            width: Config.btDeviceIconSize; height: Config.btDeviceIconSize; radius: Config.btDeviceIconSize / 2
                                            color: modelData.connected ? Theme.blue : Theme.surface0
                                            Behavior on color { ColorAnimation { duration: 200 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf293"
                                                color: modelData.connected ? Theme.crust : Theme.overlay0
                                                font.pixelSize: 14; font.family: Theme.iconFont
                                            }
                                        }

                                        // Name + status
                                        Column {
                                            Layout.fillWidth: true; spacing: 1
                                            Text {
                                                text: modelData.name || "Unknown"
                                                color: modelData.connected ? Theme.blue : Theme.text
                                                font.pixelSize: 12; font.family: Theme.fontFamily
                                                font.bold: modelData.connected
                                                elide: Text.ElideRight; width: parent.width
                                            }
                                            Text {
                                                text: isConnecting ? "Connecting..." : modelData.connected ? (modelData.batteryAvailable ? "Connected \u2022 " + Math.round(modelData.battery * 100) + "%" : "Connected") : modelData.bonded ? "Paired" : "Available"
                                                color: isConnecting ? Theme.blue : modelData.connected ? Theme.green : Theme.overlay0
                                                font.pixelSize: 9; font.family: Theme.fontFamily
                                            }
                                        }

                                        // Action button (visible when not connecting)
                                        Rectangle {
                                            width: 28; height: 28; radius: 14
                                            color: btActionMouse.containsMouse ? (modelData.connected ? Theme.red : Theme.blue) : Theme.surface0
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            visible: !isConnecting

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.connected ? "\uf127" : "\uf0c1"
                                                color: btActionMouse.containsMouse ? Theme.crust : Theme.subtext0
                                                font.pixelSize: 10; font.family: Theme.iconFont
                                            }

                                            MouseArea {
                                                id: btActionMouse; anchors.fill: parent
                                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.connected = !modelData.connected
                                            }
                                        }

                                        // Connecting spinner
                                        Item {
                                            id: btSpinner
                                            width: 28; height: 28
                                            visible: isConnecting
                                            property real sweep: 30
                                            property real tailProgress: 0
                                            property real cycleBase: 0

                                            Item {
                                                anchors.centerIn: parent
                                                width: 28; height: 28
                                                RotationAnimator on rotation { from: 0; to: 360; duration: 750; loops: Animation.Infinite; running: isConnecting }

                                                Shape {
                                                    anchors.fill: parent
                                                    ShapePath {
                                                        strokeColor: Theme.blue; strokeWidth: 2
                                                        fillColor: "transparent"; capStyle: ShapePath.RoundCap
                                                        PathAngleArc {
                                                            centerX: 14; centerY: 14; radiusX: 12; radiusY: 12
                                                            startAngle: btSpinner.cycleBase + btSpinner.tailProgress * 270 - 90
                                                            sweepAngle: btSpinner.sweep
                                                        }
                                                    }
                                                }
                                            }

                                            SequentialAnimation {
                                                loops: Animation.Infinite; running: isConnecting
                                                ParallelAnimation {
                                                    NumberAnimation { target: btSpinner; property: "sweep"; from: 30; to: 300; duration: 525; easing.type: Easing.InOutCubic }
                                                    NumberAnimation { target: btSpinner; property: "tailProgress"; from: 0; to: 0; duration: 525 }
                                                }
                                                ParallelAnimation {
                                                    NumberAnimation { target: btSpinner; property: "sweep"; from: 300; to: 30; duration: 975; easing.type: Easing.InOutCubic }
                                                    NumberAnimation { target: btSpinner; property: "tailProgress"; from: 0; to: 1; duration: 975; easing.type: Easing.InOutCubic }
                                                }
                                                ScriptAction { script: { btSpinner.cycleBase += 270; btSpinner.tailProgress = 0; } }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf0c1"
                                                color: Theme.blue
                                                font.pixelSize: 10; font.family: Theme.iconFont
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: btDevMouse; anchors.fill: parent
                                        hoverEnabled: true; z: -1
                                    }
                                }
                            }
                        }
                    }

                }

                // Scan line anchored to panel bottom
                Rectangle {
                    id: btScanLine
                    visible: root.btPowered && root.btScanning
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.left: btContent.left
                    anchors.right: btContent.right
                    height: 3; radius: 1.5
                    color: Qt.rgba(137/255, 180/255, 250/255, 0.15)
                    clip: true
                    property real bar1Pos: -0.6
                    property real bar2Pos: -0.6
                    SequentialAnimation {
                        loops: Animation.Infinite; running: root.btScanning
                        ParallelAnimation {
                            NumberAnimation { target: btScanLine; property: "bar1Pos"; from: -0.6; to: 1.0; duration: 1980; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: btScanLine; property: "bar2Pos"; from: -0.6; to: -0.6; duration: 1980 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: btScanLine; property: "bar2Pos"; from: -0.6; to: 1.0; duration: 1020; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: btScanLine; property: "bar1Pos"; from: 1.0; to: 1.0; duration: 1020 }
                        }
                        ScriptAction { script: { btScanLine.bar1Pos = -0.6; btScanLine.bar2Pos = -0.6; } }
                    }
                    Rectangle { x: btScanLine.bar1Pos * btScanLine.width; width: 0.6 * btScanLine.width; height: 3; radius: 1.5; color: Theme.blue }
                    Rectangle { x: btScanLine.bar2Pos * btScanLine.width; width: 0.6 * btScanLine.width; height: 3; radius: 1.5; color: Theme.blue }
                }
            }
        }

        // Hover-to-open for WiFi icon
        Connections {
            target: networkWidget
            function onHoveredChanged() {
                if (networkWidget.hovered) {
                    if (root.activePopup !== "wifi" && !root.wifiJustClosed) {
                        root.togglePopup("wifi");
                    } else if (root.wifiOpen) {
                        closeTimer.stop();
                    }
                } else if (root.wifiOpen && !wifiPanelHover.containsMouse) {
                    closeTimer.restart();
                }
            }
        }

        // Hover-to-open for Bluetooth icon
        Connections {
            target: btWidget
            function onHoveredChanged() {
                if (btWidget.hovered) {
                    if (root.activePopup !== "bluetooth" && !root.btJustClosed) {
                        root.togglePopup("bluetooth");
                    } else if (root.btOpen) {
                        closeTimer.stop();
                    }
                } else if (root.btOpen && !btPanelHover.containsMouse) {
                    closeTimer.restart();
                }
            }
        }

        Timer {
            id: closeTimer
            interval: Config.animPanelCloseDuration
            onTriggered: {
                if (root.clockOpen && !panelHover.containsMouse)
                    root.activePopup = "";
                else if (root.wifiOpen && !wifiPanelHover.containsMouse && !networkWidget.hovered)
                    root.activePopup = "";
                else if (root.btOpen && !btPanelHover.containsMouse && !btWidget.hovered)
                    root.activePopup = "";
            }
        }

        // ===== UNIFIED SHAPE — bar + panel as one continuous path =====
        Shape {
            id: bgShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            property real r: Theme.barRadius
            property real m: Theme.barMargin
            property real barB: Theme.barHeight
            property bool showWifiShape: root.wifiOpen || (root.activePopup === "" && root.lastPopup === "wifi" && mainWindow.panelAnimHeight > 1)
            property bool showBtShape: root.btOpen || (root.activePopup === "" && root.lastPopup === "bluetooth" && mainWindow.panelAnimHeight > 1)
            property real pw: showWifiShape ? mainWindow.wifiPanelWidth : showBtShape ? mainWindow.btPanelWidth : 280
            property real pL: showWifiShape ? mainWindow.wifiPanelLeft : showBtShape ? mainWindow.btPanelLeft : (width - pw) / 2
            property real pR: pL + pw
            property real pB: barB + mainWindow.panelAnimHeight
            property real w: width

            // Closed bar shape
            ShapePath {
                fillColor: mainWindow.panelAnimHeight > 1 ? "transparent" : Theme.barBg
                strokeColor: mainWindow.panelAnimHeight > 1 ? "transparent" : Theme.surface1
                strokeWidth: 2

                startX: bgShape.m + bgShape.r
                startY: bgShape.m

                PathLine { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.m }
                PathArc { x: bgShape.w - bgShape.m; y: bgShape.m + bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.w - bgShape.m; y: bgShape.barB - bgShape.r }
                PathArc { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.barB; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.m + bgShape.r; y: bgShape.barB }
                PathArc { x: bgShape.m; y: bgShape.barB - bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.m; y: bgShape.m + bgShape.r }
                PathArc { x: bgShape.m + bgShape.r; y: bgShape.m; radiusX: bgShape.r; radiusY: bgShape.r }
            }

            // Open bar+panel T-shape
            ShapePath {
                fillColor: mainWindow.panelAnimHeight > 1 ? Theme.barBg : "transparent"
                strokeColor: mainWindow.panelAnimHeight > 1 ? Theme.surface1 : "transparent"
                strokeWidth: 2

                startX: bgShape.m + bgShape.r
                startY: bgShape.m

                PathLine { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.m }
                PathArc { x: bgShape.w - bgShape.m; y: bgShape.m + bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.w - bgShape.m; y: bgShape.barB - bgShape.r }
                PathArc { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.barB; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.pR + bgShape.r; y: bgShape.barB }
                PathArc { x: bgShape.pR; y: bgShape.barB + bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r; direction: PathArc.Counterclockwise }
                PathLine { x: bgShape.pR; y: bgShape.pB - bgShape.r }
                PathArc { x: bgShape.pR - bgShape.r; y: bgShape.pB; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.pL + bgShape.r; y: bgShape.pB }
                PathArc { x: bgShape.pL; y: bgShape.pB - bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.pL; y: bgShape.barB + bgShape.r }
                PathArc { x: bgShape.pL - bgShape.r; y: bgShape.barB; radiusX: bgShape.r; radiusY: bgShape.r; direction: PathArc.Counterclockwise }
                PathLine { x: bgShape.m + bgShape.r; y: bgShape.barB }
                PathArc { x: bgShape.m; y: bgShape.barB - bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                PathLine { x: bgShape.m; y: bgShape.m + bgShape.r }
                PathArc { x: bgShape.m + bgShape.r; y: bgShape.m; radiusX: bgShape.r; radiusY: bgShape.r }
            }
        }

        // ===== BAR CONTENT =====
        Item {
            id: barContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.barMargin
            anchors.rightMargin: Theme.barMargin
            anchors.topMargin: Theme.barMargin
            height: Theme.barHeight - Theme.barMargin

            Row {
                id: leftSection
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPadding
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.widgetSpacing
                Workspaces {}
            }

            Item {
                anchors.centerIn: parent
                height: parent.height
                width: clockContent.implicitWidth
                Clock {
                    id: clockContent
                    anchors.centerIn: parent
                    activePopup: root.activePopup
                }
            }

            Row {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: Theme.widgetPadding
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.widgetSpacing
                MediaPlayer {}
                Volume { barWindow: mainWindow }
                Battery { barWindow: mainWindow; activePopup: root.activePopup; onTogglePopup: root.togglePopup("battery") }
                Bluetooth {
                    id: btWidget
                    activePopup: root.activePopup
                    onTogglePopup: root.togglePopup("bluetooth")
                }
                NetworkStatus {
                    id: networkWidget
                    activePopup: root.activePopup
                    onTogglePopup: root.togglePopup("wifi")
                }
                NotificationBell { unreadCount: root.notifUnreadCount }
                SysTray {}
            }
        }
    }
}
