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

    function syncFromValue() {
        let index = model.indexOf(value);
        currentIndex = Math.max(0, index);
    }

    Component.onCompleted: syncFromValue()
    onValueChanged: syncFromValue()
    onModelChanged: syncFromValue()

    onSelected: (index, val) => {
        currentIndex = index;
        Config.set(root.section, root.key, val);
    }
}
