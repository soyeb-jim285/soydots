import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

Quill.Dropdown {
    id: root
    Layout.fillWidth: true

    property string section: ""
    property string key: ""
    property string value: ""

    currentIndex: Math.max(0, model.indexOf(value))

    onSelected: (index, val) => Config.set(root.section, root.key, val)
}
