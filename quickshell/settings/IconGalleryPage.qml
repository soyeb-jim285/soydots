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
        "AlertCircle", "AlignJustify", "Battery", "Bell", "BellOff",
        "Bluetooth", "BluetoothConnected", "BluetoothOff", "Calendar",
        "Camera", "Check", "ChevronDown", "ChevronLeft", "ChevronRight",
        "ChevronUp", "Clipboard", "Clock", "Cloud", "Coffee", "Copy",
        "CopyPath", "Download", "Ethernet", "ExternalLink", "Eye",
        "EyeOff", "FileText", "Filter", "Folder", "FolderPen", "Grid",
        "HardDrive", "HardDriveOff", "Home", "Image", "Info", "Keyboard",
        "Link", "List", "Lock", "LockOpen", "LogOut", "Monitor", "Moon",
        "Music", "Palette", "PanelLeft", "PanelTop", "Pause", "Pin",
        "PinOff", "Play", "Plus", "Power", "RefreshCw", "Rocket",
        "Scissors", "Search", "Settings", "SkipBack", "SkipForward",
        "SlidersH", "Sun", "Terminal", "Trash", "TriangleAlert", "Undo",
        "Unlink", "User", "Video", "Volume", "Volume1", "Volume2",
        "VolumeX", "Wifi", "WifiOff", "WifiSector", "WifiStrength",
        "X", "Zap"
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

    // Icon grid — calculates columns to fill width evenly
    property real _minCellWidth: Math.max(72, root.iconSize + 36)
    property int _columns: Math.max(1, Math.floor(width / _minCellWidth))
    property real _cellWidth: width / _columns

    Grid {
        Layout.fillWidth: true
        columns: root._columns

        Repeater {
            model: root.filteredIcons

            Item {
                required property string modelData
                width: root._cellWidth
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
                        width: root._cellWidth - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        color: Config.subtext0
                        font.pixelSize: 9; font.family: Config.fontFamily
                    }
                }
            }
        }
    }
}
