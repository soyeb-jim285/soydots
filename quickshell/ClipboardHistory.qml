pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "icons"
import "quill" as Quill

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
        if (decodeProc.running) {
            decodeProc.pendingId = item.id;
        } else {
            decodeProc.itemId = item.id;
            decodeProc.running = true;
        }
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
        onRunningChanged: {
            if (!running && pendingId !== "") {
                itemId = pendingId;
                pendingId = "";
                running = true;
            }
        }
        property string pendingId: ""
    }

    LazyLoader {
        id: clipLoader
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-clipboard"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Background overlay — color alpha so blur ignore_alpha works
            Rectangle {
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * 0.25)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on fadeIn {
                    from: 0; to: 1
                    duration: Config.animClipboardFadeDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Centered clipboard panel
            Rectangle {
                id: container
                anchors.centerIn: parent
                width: Config.clipboardWidth
                height: Config.clipboardHeight
                color: Theme.clipboardBg
                radius: Config.clipboardRadius
                border.color: Theme.surface1
                border.width: 1

                scale: Config.animClipboardScaleFrom
                opacity: 0
                NumberAnimation on scale {
                    from: Config.animClipboardScaleFrom; to: 1.0
                    duration: Config.animClipboardScaleDuration
                    easing.type: Easing.OutBack
                    easing.overshoot: Config.animClipboardOvershoot
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: Config.animClipboardFadeDuration
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
                    Quill.TextField {
                        id: searchBox
                        Layout.fillWidth: true
                        variant: "filled"
                        placeholder: "Search clipboard..."
                        autoFocus: root.visible
                        onTextEdited: (val) => root.searchText = val

                        Component.onCompleted: {
                            inputItem.Keys.escapePressed.connect(() => root.toggle());
                            inputItem.Keys.downPressed.connect(() => clipList.forceActiveFocus());
                            inputItem.Keys.returnPressed.connect(() => {
                                if (root.filteredItems.length > 0) root.paste(root.filteredItems[0]);
                            });
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
                        property bool keyboardNav: false
                        property real lastMouseX: -1
                        property real lastMouseY: -1

                        highlightFollowsCurrentItem: false
                        onCurrentIndexChanged: {
                            console.log("[CLIP LIST] currentIndex changed to " + currentIndex + " keyboardNav=" + keyboardNav);
                            if (currentItem)
                                positionViewAtIndex(currentIndex, ListView.Contain);
                        }
                        highlight: Rectangle {
                            width: clipList.width
                            height: clipList.currentItem ? clipList.currentItem.height : Config.clipboardItemHeight
                            radius: 8
                            color: Config.surface1
                            y: clipList.currentItem ? clipList.currentItem.y : 0
                            z: 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.InOutCubic
                                }
                            }
                            Behavior on height {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: clipItem
                            required property var modelData
                            required property int index

                            width: clipList.width
                            height: clipItem.modelData.isImage ? Config.clipboardImageItemHeight : Config.clipboardItemHeight
                            radius: 8
                            color: "transparent"
                            z: 1

                            // Item number
                            Text {
                                id: itemNumber
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignRight
                                text: clipItem.index + 1
                                color: Theme.overlay0
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                            }

                            // Image preview
                            Image {
                                id: thumbImage
                                visible: clipItem.modelData.isImage
                                anchors.left: itemNumber.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 60
                                height: 60
                                fillMode: Image.PreserveAspectFit
                                source: ""
                                sourceSize: Qt.size(120, 120)
                                cache: false

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
                                    onRunningChanged: {
                                        if (!running && itemId !== "") {
                                            thumbImage.source = "file:///tmp/cliphist-thumb-" + itemId + ".png";
                                        }
                                    }
                                }
                            }

                            // Image label
                            Row {
                                visible: clipItem.modelData.isImage
                                anchors.left: itemNumber.right
                                anchors.leftMargin: 76
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                IconImage {
                                    size: 12
                                    color: Theme.subtext0
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Image"
                                    color: Theme.subtext0
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Text content
                            Text {
                                visible: !clipItem.modelData.isImage
                                anchors.left: itemNumber.right
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
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
                                onPositionChanged: (mouse) => {
                                    let screenX = clipItem.mapToItem(null, mouse.x, mouse.y).x;
                                    let screenY = clipItem.mapToItem(null, mouse.x, mouse.y).y;
                                    if (Math.abs(screenX - clipList.lastMouseX) > 1 || Math.abs(screenY - clipList.lastMouseY) > 1) {
                                        clipList.lastMouseX = screenX;
                                        clipList.lastMouseY = screenY;
                                        console.log("[CLIP MOUSE] real move idx=" + clipItem.index);
                                        clipList.keyboardNav = false;
                                        clipList.currentIndex = clipItem.index;
                                    }
                                }
                                onContainsMouseChanged: {
                                    if (containsMouse && !clipList.keyboardNav) {
                                        console.log("[CLIP MOUSE] hover enter idx=" + clipItem.index);
                                        clipList.currentIndex = clipItem.index;
                                    }
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < root.filteredItems.length)
                                root.paste(root.filteredItems[currentIndex]);
                        }
                        Keys.onEscapePressed: root.toggle()
                        Keys.onUpPressed: {
                            keyboardNav = true;
                            console.log("[CLIP KEY] Up pressed, currentIndex=" + currentIndex + " -> " + (currentIndex - 1));
                            if (currentIndex === 0)
                                searchBox.inputItem.forceActiveFocus();
                            else
                                currentIndex--;
                        }
                        Keys.onDownPressed: {
                            keyboardNav = true;
                            console.log("[CLIP KEY] Down pressed, currentIndex=" + currentIndex + " -> " + (currentIndex + 1));
                            if (currentIndex < count - 1)
                                currentIndex++;
                        }
                        Keys.onPressed: (event) => {
                            // Forward typing to search input
                            if (!event.modifiers && event.text && event.text.length > 0) {
                                searchBox.inputItem.forceActiveFocus();
                                searchBox.text += event.text;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
