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
    property string value: ""

    Text {
        text: root.label
        color: Config.text
        font.pixelSize: 12
        font.family: Config.fontFamily
        Layout.preferredWidth: 140
    }

    Rectangle {
        Layout.fillWidth: true
        height: 28; radius: 6
        color: Config.surface0
        border.color: textInput.activeFocus ? Config.blue : Config.surface1
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 100 } }

        TextInput {
            id: textInput
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: Config.text
            font.pixelSize: 12; font.family: Config.fontFamily
            text: root.value
            clip: true
            onEditingFinished: Config.set(root.section, root.key, text)
        }
    }
}
