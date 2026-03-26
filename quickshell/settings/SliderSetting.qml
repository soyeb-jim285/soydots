import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

Quill.Slider {
    id: root
    Layout.fillWidth: true

    property string section: ""
    property string key: ""

    showValue: true

    onMoved: (val) => Config.set(root.section, root.key, val)
}
