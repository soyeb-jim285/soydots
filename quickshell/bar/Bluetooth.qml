pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import ".."

Item {
    id: root
    width: btIcon.implicitWidth + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property string activePopup
    signal togglePopup()
    property bool hovered: btMouse.containsMouse

    property var adapter: Bluetooth.defaultAdapter
    property bool powered: adapter?.enabled ?? false
    property bool connected: {
        let devs = Bluetooth.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return true;
        }
        return false;
    }

    property string icon: {
        if (!powered) return "\uf293";
        if (connected) return "\uf294";
        return "\uf293";
    }
    property color iconColor: {
        if (!powered) return Theme.overlay0;
        if (connected) return Theme.blue;
        return Theme.text;
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: btMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Text {
        id: btIcon
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: Theme.fontSizeIcon
        font.family: Theme.iconFont
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }

    MouseArea {
        id: btMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }
}
