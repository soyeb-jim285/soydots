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

    function togglePopup(name: string) {
        if (root.activePopup === name) {
            root.activePopup = "";
        } else {
            root.activePopup = name;
            if (name === "clock") {
                viewMonth = currentMonth;
                viewYear = currentYear;
                uptimeProc.running = true;
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = this.text.trim().replace("up ", "")
        }
    }

    // ===== SINGLE WINDOW for bar + panels =====
    PanelWindow {
        id: mainWindow

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 500
        exclusiveZone: Theme.barHeight
        color: "transparent"

        property real panelAnimHeight: root.clockOpen ? calendarContent.implicitHeight + 28 : 0
        Behavior on panelAnimHeight {
            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
        }

        // ===== PANEL HOVER ZONE — calendar content lives INSIDE as children =====
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
                // Open when hovering clock area within panelHover
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

            // Calendar content — as child of panelHover so containsMouse stays true
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barHeight
                width: 280
                height: Math.max(0, mainWindow.panelAnimHeight)
                clip: true

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

        Timer {
            id: closeTimer
            interval: 200
            onTriggered: {
                if (root.clockOpen && !panelHover.containsMouse)
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
            property real pw: 280
            property real pL: (width - pw) / 2
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
                NetworkStatus {}
                SysTray {}
            }
        }


    }
}
