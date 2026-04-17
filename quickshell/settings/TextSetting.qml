import QtQuick
import QtQuick.Layouts
import ".."
import "../icons"

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12

    property string label: ""
    property string section: ""
    property string key: ""
    property string value: ""

    // Tracks the last-committed value so we can show a save button only when
    // the visible text differs. editingFinished fires on Enter or focus-loss
    // but users often click outside the settings window entirely, which can
    // miss focus-loss on some compositors — the explicit save button makes
    // the commit unambiguous.
    property string _committed: value
    readonly property bool _dirty: textInput.text !== _committed

    onValueChanged: _committed = value

    function commit() {
        if (!_dirty) return;
        Config.set(section, key, textInput.text);
        _committed = textInput.text;
    }

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
        border.color: textInput.activeFocus
            ? Config.blue
            : (root._dirty ? Config.yellow : Config.surface1)
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
            onAccepted: root.commit()
            onEditingFinished: root.commit()
        }
    }

    // Save button — only visible while there are unsaved edits. Provides a
    // reliable commit path that doesn't depend on focus-loss semantics.
    Rectangle {
        Layout.preferredWidth: root._dirty ? 28 : 0
        Layout.preferredHeight: 28
        radius: 6
        visible: root._dirty
        color: saveMouse.containsMouse ? Config.green : Config.surface0
        border.color: Config.green
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 120 } }

        IconCheck {
            anchors.centerIn: parent
            size: 14
            color: saveMouse.containsMouse ? Config.crust : Config.green
        }

        MouseArea {
            id: saveMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.commit()
        }
    }
}
