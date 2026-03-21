pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."
import "../icons"

PopupWindow {
    id: popup
    implicitWidth: Config.calendarWidth
    implicitHeight: panelContent.implicitHeight + 24
    color: "transparent"

    property string uptimeText: ""
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property int viewMonth: currentMonth
    property int viewYear: currentYear
    property int today: new Date().getDate()

    function daysInMonth(month: int, year: int): int {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfWeek(month: int, year: int): int {
        return new Date(year, month, 1).getDay();
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    property var monthNames: ["January", "February", "March", "April", "May", "June",
                               "July", "August", "September", "October", "November", "December"]
    property var dayHeaders: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // Build the calendar grid: 6 rows x 7 cols
    property var calendarDays: {
        let days = [];
        let totalDays = daysInMonth(viewMonth, viewYear);
        let startDay = firstDayOfWeek(viewMonth, viewYear);

        // Previous month trailing days
        let prevDays = viewMonth === 0 ? daysInMonth(11, viewYear - 1) : daysInMonth(viewMonth - 1, viewYear);
        for (let i = startDay - 1; i >= 0; i--) {
            days.push({ day: prevDays - i, current: false });
        }

        // Current month days
        for (let d = 1; d <= totalDays; d++) {
            days.push({ day: d, current: true });
        }

        // Next month leading days
        let remaining = 42 - days.length;
        for (let i = 1; i <= remaining; i++) {
            days.push({ day: i, current: false });
        }

        return days;
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: popup.uptimeText = this.text.trim().replace("up ", "")
        }
    }

    Timer {
        interval: 60000
        running: popup.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    // Panel background — connected to bar (flat top, rounded bottom)
    Rectangle {
        id: panelBg
        anchors.fill: parent
        color: Theme.panelBg
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.barRadius
        bottomRightRadius: Theme.barRadius
        border.color: Theme.surface1
        border.width: 1

        // Slide down + fade in animation
        transform: Translate { id: slideTransform; y: -10 }
        opacity: 0
        NumberAnimation on opacity {
            from: 0; to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
            running: true
        }
        NumberAnimation {
            target: slideTransform
            property: "y"
            from: -10; to: 0
            duration: 250
            easing.type: Easing.OutCubic
            running: true
        }

        ColumnLayout {
            id: panelContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Month nav header
            RowLayout {
                Layout.fillWidth: true

                IconChevronLeft {
                    size: 12
                    color: prevMouse.containsMouse ? Theme.text : Theme.overlay0
                    Behavior on color { ColorAnimation { duration: 100 } }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.prevMonth()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: popup.monthNames[popup.viewMonth] + " " + popup.viewYear
                    color: Theme.blue
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                IconChevronRight {
                    size: 12
                    color: nextMouse.containsMouse ? Theme.text : Theme.overlay0
                    Behavior on color { ColorAnimation { duration: 100 } }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.nextMonth()
                    }
                }
            }

            // Day headers
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Repeater {
                    model: popup.dayHeaders

                    Text {
                        required property string modelData
                        width: Config.calendarCellWidth
                        text: modelData
                        color: Theme.overlay0
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Calendar grid
            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                spacing: 0

                Repeater {
                    model: popup.calendarDays

                    Rectangle {
                        required property var modelData
                        required property int index

                        property bool isToday: modelData.current
                            && modelData.day === popup.today
                            && popup.viewMonth === popup.currentMonth
                            && popup.viewYear === popup.currentYear

                        width: Config.calendarCellWidth
                        height: Config.calendarCellHeight
                        radius: Config.calendarCellRadius
                        color: isToday ? Theme.blue : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.day
                            color: parent.isToday ? Theme.crust
                                : parent.modelData.current ? Theme.text
                                : Theme.surface2
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            font.bold: parent.isToday
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

            // Uptime
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                IconClock {
                    size: 13
                    color: Theme.peach
                }

                Text {
                    text: popup.uptimeText || "..."
                    color: Theme.subtext0
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                }
            }
        }
    }
}
