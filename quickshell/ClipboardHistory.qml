pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool visible: false
    property string searchText: ""
    property var clipItems: []
    property var filteredItems: {
        let query = searchText.toLowerCase().trim();
        if (query === "") return clipItems;
        return clipItems.filter(item => item.text.toLowerCase().includes(query));
    }

    function toggle() {
        root.visible = !root.visible;
        if (root.visible) {
            root.searchText = "";
            refreshProc.running = true;
        }
    }

    function paste(item) {
        decodeProc.itemId = item.id;
        decodeProc.running = true;
        root.visible = false;
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            root.toggle();
        }
    }

    // Fetch clipboard history
    Process {
        id: refreshProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let items = [];
                for (let line of lines) {
                    let tabIdx = line.indexOf("\t");
                    if (tabIdx > 0) {
                        let id = line.substring(0, tabIdx).trim();
                        let text = line.substring(tabIdx + 1);
                        if (text.length > 0) {
                            let isImage = text.startsWith("[[ binary data");
                            items.push({ id: id, text: isImage ? "Image" : text, isImage: isImage });
                        }
                    }
                }
                root.clipItems = items;
            }
        }
    }

    // Decode and copy selected item
    Process {
        id: decodeProc
        property string itemId: ""
        command: ["bash", "-c", "cliphist decode " + itemId + " | wl-copy"]
    }

    LazyLoader {
        id: clipLoader
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Background overlay
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on opacity {
                    from: 0; to: 0.4
                    duration: 200
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Centered clipboard panel
            Rectangle {
                id: container
                anchors.centerIn: parent
                width: 500
                height: 450
                color: Theme.mantle
                radius: 16
                border.color: Theme.surface1
                border.width: 1

                scale: 0.85
                opacity: 0
                NumberAnimation on scale {
                    from: 0.85; to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                    running: true
                }

                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Header
                    Text {
                        text: "Clipboard History"
                        color: Theme.blue
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Search box
                    Rectangle {
                        id: searchBox
                        Layout.fillWidth: true
                        height: 42
                        radius: 12
                        color: Theme.surface0

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: 14
                            font.family: Theme.fontFamily
                            clip: true
                            focus: root.visible

                            onTextChanged: root.searchText = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search clipboard..."
                                color: Theme.overlay0
                                font: searchInput.font
                                visible: !searchInput.text
                            }

                            Keys.onEscapePressed: root.toggle()
                            Keys.onDownPressed: clipList.forceActiveFocus()
                            Keys.onReturnPressed: {
                                if (root.filteredItems.length > 0)
                                    root.paste(root.filteredItems[0]);
                            }
                        }
                    }

                    // Clipboard list
                    ListView {
                        id: clipList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: root.filteredItems
                        currentIndex: 0

                        delegate: Rectangle {
                            id: clipItem
                            required property var modelData
                            required property int index

                            width: clipList.width
                            height: clipItem.modelData.isImage ? 80 : 38
                            radius: 8
                            color: (clipList.currentIndex === index)
                                ? Theme.surface1
                                : clipMouse.containsMouse ? Theme.surface0 : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            // Image preview
                            Image {
                                visible: clipItem.modelData.isImage
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 60
                                height: 60
                                fillMode: Image.PreserveAspectFit
                                source: clipItem.modelData.isImage ? "file:///tmp/cliphist-thumb-" + clipItem.modelData.id + ".png" : ""
                                sourceSize: Qt.size(120, 120)

                                Component.onCompleted: {
                                    if (clipItem.modelData.isImage) {
                                        thumbProc.itemId = clipItem.modelData.id;
                                        thumbProc.running = true;
                                    }
                                }

                                Process {
                                    id: thumbProc
                                    property string itemId
                                    command: ["bash", "-c", "cliphist decode " + itemId + " > /tmp/cliphist-thumb-" + itemId + ".png"]
                                }
                            }

                            // Image label
                            Text {
                                visible: clipItem.modelData.isImage
                                anchors.left: parent.left
                                anchors.leftMargin: 84
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uf03e  Image"
                                color: Theme.subtext0
                                font.pixelSize: 12
                                font.family: Theme.iconFont
                            }

                            // Text content
                            Text {
                                visible: !clipItem.modelData.isImage
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: clipItem.modelData.text
                                color: Theme.text
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            MouseArea {
                                id: clipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.paste(clipItem.modelData)
                                onContainsMouseChanged: {
                                    if (containsMouse)
                                        clipList.currentIndex = clipItem.index;
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < root.filteredItems.length)
                                root.paste(root.filteredItems[currentIndex]);
                        }
                        Keys.onEscapePressed: root.toggle()
                        Keys.onUpPressed: {
                            if (currentIndex === 0)
                                searchInput.forceActiveFocus();
                            else
                                currentIndex--;
                        }
                    }
                }
            }
        }
    }
}
