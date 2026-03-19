pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
        } else {
            root.activePopup = name;
            root.wifiJustClosed = false;
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
        interval: 3000
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
        property real wifiPanelWidth: 300
        property real wifiIconWindowX: barContent.x + rightSection.x + networkWidget.x + networkWidget.width / 2
        property real wifiPanelLeft: {
            let left = wifiIconWindowX - wifiPanelWidth / 2;
            return Math.max(Theme.barMargin + 2 * Theme.barRadius,
                            Math.min(left, width - wifiPanelWidth - Theme.barMargin - 2 * Theme.barRadius));
        }

        mask: Region {
            // Bar area — full width
            x: 0; y: 0
            width: mainWindow.width
            height: Theme.barHeight

            // Calendar panel area
            Region {
                item: panelHover
                intersection: Intersection.Combine
            }

            // WiFi panel area
            Region {
                item: wifiPanelHover
                intersection: Intersection.Combine
            }
        }

        property real panelAnimHeight: root.clockOpen ? calendarContent.implicitHeight + 28
            : root.wifiOpen ? wifiContent.implicitHeight + 28
            : 0
        Behavior on panelAnimHeight {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }

        // ===== CALENDAR HOVER ZONE =====
        MouseArea {
            id: panelHover
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            z: 10
            width: 280 + Theme.barRadius * 2
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
                width: 280
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
                            Text { required property string modelData; width: 34; text: modelData; color: Theme.overlay0; font.pixelSize: 10; font.family: Theme.fontFamily; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        }
                    }

                    Grid {
                        Layout.alignment: Qt.AlignHCenter; columns: 7; spacing: 0
                        Repeater {
                            model: root.calendarDays
                            Rectangle {
                                required property var modelData; required property int index
                                property bool isToday: modelData.current && modelData.day === root.today && root.viewMonth === root.currentMonth && root.viewYear === root.currentYear
                                width: 34; height: 28; radius: 6
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

                    // Header
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
                                from: 0; to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: root.wifiScanning
                            }

                            MouseArea {
                                id: rescanMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wifiRescanProc.running = true;
                                    rescanDelay.restart();
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.surface1
                    }

                    // Empty/scanning state
                    Text {
                        visible: root.wifiNetworks.length === 0
                        text: root.wifiScanning ? "Scanning..." : "No networks found"
                        color: Theme.subtext0
                        font.pixelSize: 12; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }

                    // Network list
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 250)
                        contentHeight: networkCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        visible: root.wifiNetworks.length > 0

                        ColumnLayout {
                            id: networkCol
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: root.wifiNetworks

                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 36; radius: 6
                                    color: netItemMouse.containsMouse ? Theme.surface0 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        // Signal icon
                                        Text {
                                            text: "\uf1eb"
                                            color: modelData.active ? Theme.green
                                                : modelData.signal > 66 ? Theme.text
                                                : modelData.signal > 33 ? Theme.yellow
                                                : Theme.red
                                            font.pixelSize: 14; font.family: Theme.iconFont
                                            opacity: Math.max(0.3, modelData.signal / 100)
                                        }

                                        // SSID
                                        Text {
                                            text: modelData.ssid
                                            color: modelData.active ? Theme.green : Theme.text
                                            font.pixelSize: 12; font.family: Theme.fontFamily
                                            font.bold: modelData.active
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Connecting indicator
                                        Text {
                                            visible: root.wifiConnectingSSID === modelData.ssid
                                            text: "..."
                                            color: Theme.blue
                                            font.pixelSize: 12; font.family: Theme.fontFamily
                                        }

                                        // Lock icon
                                        Text {
                                            visible: modelData.security !== "" && modelData.security !== "--"
                                            text: "\uf023"
                                            color: Theme.overlay0
                                            font.pixelSize: 10; font.family: Theme.iconFont
                                        }

                                        // Signal %
                                        Text {
                                            text: modelData.signal + "%"
                                            color: Theme.overlay0
                                            font.pixelSize: 10; font.family: Theme.fontFamily
                                        }

                                        // Connected check
                                        Text {
                                            visible: modelData.active
                                            text: "\uf00c"
                                            color: Theme.green
                                            font.pixelSize: 12; font.family: Theme.iconFont
                                        }
                                    }

                                    MouseArea {
                                        id: netItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.active) return;
                                            wifiConnectProc.ssid = modelData.ssid;
                                            wifiConnectProc.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Password section
                    ColumnLayout {
                        visible: root.wifiPasswordSSID !== ""
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.surface1
                        }

                        Text {
                            text: "Password for " + root.wifiPasswordSSID
                            color: Theme.subtext0
                            font.pixelSize: 11; font.family: Theme.fontFamily
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                height: 30; radius: 6
                                color: Theme.surface0
                                border.color: wifiPassInput.activeFocus ? Theme.blue : Theme.surface1
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                TextInput {
                                    id: wifiPassInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.text
                                    font.pixelSize: 12; font.family: Theme.fontFamily
                                    echoMode: TextInput.Password
                                    clip: true
                                    onAccepted: root.submitWifiPassword()
                                }
                            }

                            Rectangle {
                                width: 30; height: 30; radius: 6
                                color: connectBtnMouse.containsMouse ? Theme.blue : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf054"
                                    color: Theme.text
                                    font.pixelSize: 12; font.family: Theme.iconFont
                                }

                                MouseArea {
                                    id: connectBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.submitWifiPassword()
                                }
                            }
                        }
                    }

                    // Error
                    Text {
                        visible: root.wifiError !== ""
                        text: root.wifiError
                        color: Theme.red
                        font.pixelSize: 10; font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }

                    // Bottom padding
                    Item { height: 4; Layout.fillWidth: true }
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

        Timer {
            id: closeTimer
            interval: 200
            onTriggered: {
                if (root.clockOpen && !panelHover.containsMouse)
                    root.activePopup = "";
                else if (root.wifiOpen && !wifiPanelHover.containsMouse && !networkWidget.hovered)
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
            property real pw: showWifiShape ? mainWindow.wifiPanelWidth : 280
            property real pL: showWifiShape ? mainWindow.wifiPanelLeft : (width - pw) / 2
            property real pR: pL + pw
            property real pB: barB + mainWindow.panelAnimHeight
            property real w: width

            // Closed bar shape
            ShapePath {
                fillColor: mainWindow.panelAnimHeight > 1 ? "transparent" : Theme.mantle
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
                fillColor: mainWindow.panelAnimHeight > 1 ? Theme.mantle : "transparent"
                strokeColor: mainWindow.panelAnimHeight > 1 ? Theme.surface1 : "transparent"
                strokeWidth: 2

                startX: bgShape.m + bgShape.r
                startY: bgShape.m

                // Top edge
                PathLine { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.m }
                // Top-right corner
                PathArc { x: bgShape.w - bgShape.m; y: bgShape.m + bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                // Right side down
                PathLine { x: bgShape.w - bgShape.m; y: bgShape.barB - bgShape.r }
                // Bottom-right corner of bar
                PathArc { x: bgShape.w - bgShape.m - bgShape.r; y: bgShape.barB; radiusX: bgShape.r; radiusY: bgShape.r }
                // Bottom edge to right inverted corner start
                PathLine { x: bgShape.pR + bgShape.r; y: bgShape.barB }
                // Right inverted corner: 90° concave arc
                PathArc { x: bgShape.pR; y: bgShape.barB + bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r; direction: PathArc.Counterclockwise }
                // Panel right side down
                PathLine { x: bgShape.pR; y: bgShape.pB - bgShape.r }
                // Panel bottom-right corner
                PathArc { x: bgShape.pR - bgShape.r; y: bgShape.pB; radiusX: bgShape.r; radiusY: bgShape.r }
                // Panel bottom edge
                PathLine { x: bgShape.pL + bgShape.r; y: bgShape.pB }
                // Panel bottom-left corner
                PathArc { x: bgShape.pL; y: bgShape.pB - bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                // Panel left side up
                PathLine { x: bgShape.pL; y: bgShape.barB + bgShape.r }
                // Left inverted corner: 90° concave arc
                PathArc { x: bgShape.pL - bgShape.r; y: bgShape.barB; radiusX: bgShape.r; radiusY: bgShape.r; direction: PathArc.Counterclockwise }
                // Bottom edge to left
                PathLine { x: bgShape.m + bgShape.r; y: bgShape.barB }
                // Bottom-left corner of bar
                PathArc { x: bgShape.m; y: bgShape.barB - bgShape.r; radiusX: bgShape.r; radiusY: bgShape.r }
                // Left side up
                PathLine { x: bgShape.m; y: bgShape.m + bgShape.r }
                // Top-left corner
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
                Bluetooth {}
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
