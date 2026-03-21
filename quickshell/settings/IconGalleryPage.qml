import QtQuick
import QtQuick.Layouts
import "../icons"
import ".."

ColumnLayout {
    id: root
    spacing: 6

    property real iconSize: 24
    property color iconColor: Config.text
    property string searchText: ""

    property var iconNames: [
        "AlertCircle", "Battery", "Bell", "BellOff", "Bluetooth",
        "BluetoothConnected", "BluetoothOff", "Calendar", "Camera",
        "Check", "ChevronLeft", "ChevronRight", "Clipboard", "Clock",
        "Cloud", "Coffee", "Ethernet", "Eye", "EyeOff", "Image",
        "Info", "Keyboard", "Link", "Lock", "LockOpen", "LogOut",
        "Moon", "Palette", "PanelTop", "Pause", "Play", "Plus",
        "Power", "RefreshCw", "Rocket", "Settings", "SkipBack",
        "SkipForward", "SlidersH", "Sun", "Trash", "TriangleAlert",
        "Undo", "Unlink", "User", "Volume", "Volume1", "Volume2",
        "VolumeX", "Wifi", "X", "Zap"
    ]

    property var filteredIcons: {
        if (!searchText) return iconNames;
        let s = searchText.toLowerCase();
        return iconNames.filter(n => n.toLowerCase().includes(s));
    }

    property var colorOptions: [
        { name: "Text", color: Config.text },
        { name: "Subtext", color: Config.subtext0 },
        { name: "Blue", color: Config.blue },
        { name: "Red", color: Config.red },
        { name: "Green", color: Config.green },
        { name: "Yellow", color: Config.yellow },
        { name: "Mauve", color: Config.mauve },
        { name: "Peach", color: Config.peach },
        { name: "Teal", color: Config.teal }
    ]

    // Search bar
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 6
        color: Config.surface0
        TextInput {
            anchors.fill: parent; anchors.margins: 8
            color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily
            onTextChanged: root.searchText = text
            Text {
                visible: !parent.text
                text: "Search icons..."; color: Config.overlay0
                font.pixelSize: 12; font.family: Config.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Size buttons
    Row {
        spacing: 6
        Text { text: "Size:"; color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily; anchors.verticalCenter: parent.verticalCenter }
        Repeater {
            model: [12, 16, 20, 24, 32, 48]
            Rectangle {
                required property int modelData
                width: 32; height: 24; radius: 4
                color: root.iconSize === modelData ? Config.blue : Config.surface0
                Text {
                    anchors.centerIn: parent; text: parent.modelData
                    color: root.iconSize === parent.modelData ? Config.crust : Config.text
                    font.pixelSize: 10; font.family: Config.fontFamily
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.iconSize = parent.modelData
                }
            }
        }
    }

    // Color picker row
    Row {
        spacing: 6
        Repeater {
            model: root.colorOptions
            Rectangle {
                required property var modelData
                width: 24; height: 24; radius: 12
                color: modelData.color
                border.width: root.iconColor === modelData.color ? 2 : 0
                border.color: Config.text
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.iconColor = parent.modelData.color
                }
            }
        }
    }

    // Icon grid (Flow instead of GridView — works inside Flickable scroll)
    Flow {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: root.filteredIcons

            Item {
                required property string modelData
                width: Math.max(80, root.iconSize + 40)
                height: root.iconSize + 40

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Loader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "../icons/Icon" + modelData + ".qml"
                        onLoaded: {
                            item.size = Qt.binding(() => root.iconSize);
                            item.color = Qt.binding(() => root.iconColor);
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: Config.subtext0
                        font.pixelSize: 9; font.family: Config.fontFamily
                    }
                }
            }
        }
    }
}
