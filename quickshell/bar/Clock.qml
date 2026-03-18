pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import ".."

Item {
    id: root
    width: clockRow.implicitWidth + Theme.widgetPadding * 2
    height: parent?.height ?? Theme.barHeight

    required property string activePopup

    property string timeText: ""
    property string dateText: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            root.timeText = Qt.formatDateTime(now, "h:mm AP");
            root.dateText = Qt.formatDateTime(now, "ddd, MMM d");
        }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.timeText
            color: Theme.text
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
        }

        Rectangle {
            width: 1
            height: 14
            color: Theme.surface2
        }

        Text {
            text: root.dateText
            color: Theme.subtext0
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }
}
