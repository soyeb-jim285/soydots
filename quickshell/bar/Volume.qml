pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import ".."
import "../icons"

Item {
    id: root
    width: Theme.fontSizeIcon + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property var barWindow

    property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink]
    }

    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: volMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Item {
        id: volIcon
        width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.widgetPadding / 2

        property color iconColor: root.muted ? Theme.red : Theme.blue

        IconVolumeX {
            visible: root.muted
            size: Theme.fontSizeIcon
            color: volIcon.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconVolume2 {
            visible: !root.muted && root.volume > 0.66
            size: Theme.fontSizeIcon
            color: volIcon.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconVolume1 {
            visible: !root.muted && root.volume > 0.33 && root.volume <= 0.66
            size: Theme.fontSizeIcon
            color: volIcon.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
        IconVolume {
            visible: !root.muted && root.volume <= 0.33
            size: Theme.fontSizeIcon
            color: volIcon.iconColor
            anchors.centerIn: parent
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }

    MouseArea {
        id: volMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: (event) => {
            if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
        }

        onWheel: (event) => {
            if (root.sink?.audio) {
                let delta = event.angleDelta.y > 0 ? Config.volumeScrollIncrement : -Config.volumeScrollIncrement;
                root.sink.audio.volume = Math.max(0, Math.min(1.0, root.volume + delta));
            }
        }
    }
}
