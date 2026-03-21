import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    property var model: []
    property int currentIndex: 0
    property bool enabled: true
    signal tabChanged(int index)
    implicitHeight: 36
    opacity: enabled ? 1.0 : 0.5
    Layout.fillWidth: true
    Row {
        id: tabRow
        anchors.fill: parent
        spacing: 0
        Repeater {
            id: tabRepeater
            model: root.model
            Item {
                required property string modelData
                required property int index
                width: tabText.implicitWidth + Theme.spacingXl * 2
                height: root.height
                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData
                    color: index === root.currentIndex ? Theme.primary : Theme.textTertiary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: index === root.currentIndex
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.enabled) return;
                        root.currentIndex = index;
                        root.tabChanged(index);
                    }
                }
            }
        }
    }
    Rectangle {
        id: underline
        height: 2; radius: 1
        color: Theme.primary
        anchors.bottom: parent.bottom
        property Item currentTab: tabRepeater.itemAt(root.currentIndex)
        x: currentTab ? currentTab.x : 0
        width: currentTab ? currentTab.width : 0
        Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: Theme.surface1
    }
}
