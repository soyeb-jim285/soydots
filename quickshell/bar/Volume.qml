pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import ".."

Item {
    id: root
    width: volIcon.implicitWidth + Theme.widgetPadding
    height: parent?.height ?? Theme.barHeight

    required property var barWindow

    property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink]
    }

    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    property string icon: {
        if (muted) return "󰖁";
        if (volume > 0.66) return "\uf028";
        if (volume > 0.33) return "\uf027";
        return "\uf026";
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: volMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Text {
        id: volIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.widgetPadding / 2
        text: root.icon
        color: root.muted ? Theme.red : Theme.blue
        font.pixelSize: Theme.fontSizeIcon
        font.family: Theme.iconFont
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
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
                let delta = event.angleDelta.y > 0 ? 0.05 : -0.05;
                root.sink.audio.volume = Math.max(0, Math.min(1.0, root.volume + delta));
            }
        }
    }
}
