pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

Item {
    id: root
    width: bellIcon.implicitWidth + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property int unreadCount

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: bellMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Text {
        id: bellIcon
        anchors.centerIn: parent
        text: root.unreadCount > 0 ? "\uf0f3" : "\uf0a2"
        color: root.unreadCount > 0 ? Theme.peach : Theme.text
        font.pixelSize: Theme.fontSizeIcon
        font.family: Theme.iconFont
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }

    // Unread badge
    Rectangle {
        visible: root.unreadCount > 0
        anchors.top: bellIcon.top
        anchors.right: bellIcon.right
        anchors.topMargin: -2
        anchors.rightMargin: -4
        width: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7
        color: Theme.red

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.unreadCount > 99 ? "99+" : root.unreadCount
            color: Theme.crust
            font.pixelSize: 8
            font.family: Theme.fontFamily
            font.bold: true
        }
    }

    MouseArea {
        id: bellMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: notifShow.running = true
    }

    Process {
        id: notifShow
        command: ["quickshell", "msg", "notifications", "show"]
    }
}
