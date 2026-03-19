import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12

    property string label: ""
    property string section: ""
    property string key: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property int decimals: 0
    property real stepSize: 1

    Text {
        text: root.label
        color: Config.text
        font.pixelSize: 12
        font.family: Config.fontFamily
        Layout.preferredWidth: 140
    }

    Item {
        Layout.fillWidth: true
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Config.surface1
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
            height: 4; radius: 2
            color: Config.blue
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) - 7
            width: 14; height: 14; radius: 7
            color: sliderMouse.pressed ? Config.lavender : Config.blue
            Behavior on color { ColorAnimation { duration: 80 } }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: (event) => updateValue(event)
            onPositionChanged: (event) => { if (pressed) updateValue(event); }

            function updateValue(event) {
                let ratio = Math.max(0, Math.min(1, event.x / width));
                let raw = root.from + ratio * (root.to - root.from);
                let step = root.stepSize;
                let val = Math.round(raw / step) * step;
                if (root.decimals > 0)
                    val = parseFloat(val.toFixed(root.decimals));
                Config.set(root.section, root.key, val);
            }
        }
    }

    Rectangle {
        width: 52; height: 24; radius: 4
        color: Config.surface0
        Text {
            anchors.centerIn: parent
            text: root.decimals > 0
                ? root.value.toFixed(root.decimals)
                : Math.round(root.value)
            color: Config.text
            font.pixelSize: 11; font.family: Config.fontFamily
        }
    }
}
