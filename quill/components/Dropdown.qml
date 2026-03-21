import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    property var model: []
    property int currentIndex: 0
    property string label: ""
    property bool enabled: true
    signal selected(int index, string value)
    implicitHeight: 34
    implicitWidth: 200
    Layout.fillWidth: true
    z: dropdownOpen ? 100 : 0
    property bool dropdownOpen: false

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34
        spacing: Theme.spacingMd
        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            Layout.preferredWidth: 140
        }
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: Theme.radius
            color: Theme.surface0
            border.color: root.dropdownOpen ? Theme.primary : Theme.surface1
            border.width: 1
            opacity: root.enabled ? 1.0 : 0.5
            Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }
            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing
                anchors.rightMargin: Theme.spacing
                Text {
                    text: root.model[root.currentIndex] ?? ""
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - chevron.width
                    elide: Text.ElideRight
                }
                Text {
                    id: chevron
                    text: root.dropdownOpen ? "\uf077" : "\uf078"
                    color: Theme.textTertiary
                    font.family: Theme.iconFont
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.enabled) return;
                    root.dropdownOpen = !root.dropdownOpen;
                }
            }
        }
    }

    Rectangle {
        id: dropdownList
        visible: root.dropdownOpen
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(root.model.length * 34, 200)
        radius: Theme.radius
        color: Theme.surface0
        border.color: Theme.surface1
        border.width: 1
        z: 100
        clip: true
        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 4
            model: root.model
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                required property string modelData
                required property int index
                width: listView.width
                height: 30
                radius: Theme.radiusSm
                color: index === root.currentIndex
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    : itemMouse.containsMouse ? Theme.surface1 : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing
                    text: modelData
                    color: index === root.currentIndex ? Theme.primary : Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.selected(index, modelData);
                        root.dropdownOpen = false;
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.dropdownOpen
        parent: root.parent
        anchors.fill: parent
        color: "transparent"
        z: 99
        MouseArea {
            anchors.fill: parent
            onClicked: root.dropdownOpen = false
        }
    }

    onDropdownOpenChanged: { if (dropdownOpen) forceActiveFocus(); }
    Keys.onEscapePressed: dropdownOpen = false
    Keys.onUpPressed: { if (dropdownOpen && currentIndex > 0) currentIndex--; }
    Keys.onDownPressed: { if (dropdownOpen && currentIndex < model.length - 1) currentIndex++; }
    Keys.onReturnPressed: {
        if (dropdownOpen) {
            selected(currentIndex, model[currentIndex]);
            dropdownOpen = false;
        }
    }
}
