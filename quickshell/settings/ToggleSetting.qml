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
    property bool value: false

    Text {
        text: root.label
        color: Config.text
        font.pixelSize: 12
        font.family: Config.fontFamily
        Layout.fillWidth: true
    }

    Rectangle {
        width: 40; height: 22; radius: 11
        color: root.value ? Config.blue : Config.surface1
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.value ? parent.width - width - 2 : 2
            color: Config.text
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.set(root.section, root.key, !root.value)
        }
    }
}
