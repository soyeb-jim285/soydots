import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

Quill.Toggle {
    id: root
    Layout.fillWidth: true

    property string section: ""
    property string key: ""
    property bool value: false

    checked: value
    label: ""

    onToggled: (val) => Config.set(root.section, root.key, val)
}
