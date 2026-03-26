pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../icons"
import "../quill" as Quill

Item {
    id: root
    width: Theme.fontSizeIcon + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property int unreadCount
    property bool dndEnabled: false

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: bellMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Item {
        id: bellIcon
        width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
        anchors.centerIn: parent

        IconBell {
            visible: !root.dndEnabled
            size: Theme.fontSizeIcon
            color: root.unreadCount > 0 ? Theme.peach : Theme.text
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconBellOff {
            visible: root.dndEnabled
            size: Theme.fontSizeIcon
            color: Theme.mauve
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }

    // Unread badge
    Quill.Badge {
        visible: root.unreadCount > 0
        text: root.unreadCount > 99 ? "99+" : "" + root.unreadCount
        variant: "error"
        anchors.top: bellIcon.top
        anchors.right: bellIcon.right
        anchors.topMargin: -2
        anchors.rightMargin: -4
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
