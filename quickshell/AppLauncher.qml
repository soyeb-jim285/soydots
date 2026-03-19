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

    // Filter out system/network tools that shouldn't appear in a launcher
    property list<string> hiddenApps: [
        "avahi-discover",
        "bssh",
        "bvnc",
        "lstopo",
        "qv4l2",
        "qvidcap",
        "electron",
        "cmake-gui",
    ]

    property list<DesktopEntry> allApps: {
        let apps = Array.from(DesktopEntries.applications.values);
        return apps.filter(app => {
            let id = (app.id ?? "").toLowerCase();
            let name = (app.name ?? "").toLowerCase();
            for (let hidden of hiddenApps) {
                if (id.includes(hidden) || name.includes(hidden))
                    return false;
            }
            return true;
        });
    }

    property var filteredApps: {
        let query = searchText.toLowerCase().trim();
        if (query === "") return allApps;
        return allApps.filter(app => {
            let name = (app.name ?? "").toLowerCase();
            let generic = (app.genericName ?? "").toLowerCase();
            let comment = (app.comment ?? "").toLowerCase();
            let keywords = (app.keywords ?? []).join(" ").toLowerCase();
            return name.includes(query) || generic.includes(query) ||
                   comment.includes(query) || keywords.includes(query);
        });
    }

    function toggle() {
        root.visible = !root.visible;
        if (root.visible) {
            root.searchText = "";
        }
    }

    function launch(app) {
        if (app.runInTerminal) {
            Quickshell.execDetached(["kitty"].concat(app.command));
        } else {
            app.execute();
        }
        root.visible = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggle app launcher"
        onPressed: root.toggle()
    }

    LazyLoader {
        id: launcherLoader
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

            // Background overlay fade
            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: "#000000"
                opacity: 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on opacity {
                    id: backdropIn
                    from: 0; to: 0.4
                    duration: 200
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Centered launcher container
            Rectangle {
                id: container
                anchors.centerIn: parent
                width: 600
                height: Math.min(500, searchBox.height + resultsView.contentHeight + 40)
                color: "#1e1e2e"
                radius: 16
                border.color: "#45475a"
                border.width: 1

                // Entry animation
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
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Rectangle {
                        id: searchBox
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        color: "#313244"

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#cdd6f4"
                            font.pixelSize: 16
                            font.family: "Maple Mono"
                            clip: true
                            focus: root.visible

                            onTextChanged: root.searchText = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search apps..."
                                color: "#6c7086"
                                font: searchInput.font
                                visible: !searchInput.text
                            }

                            Keys.onEscapePressed: root.toggle()
                            Keys.onDownPressed: resultsView.forceActiveFocus()
                            Keys.onReturnPressed: {
                                if (root.filteredApps.length > 0)
                                    root.launch(root.filteredApps[0]);
                            }
                        }
                    }

                    ListView {
                        id: resultsView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: root.filteredApps
                        currentIndex: 0

                        // Smooth scrolling
                        displaced: Transition {
                            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
                        }

                        delegate: Rectangle {
                            id: appItem
                            required property var modelData
                            required property int index

                            width: resultsView.width
                            height: 44
                            radius: 10
                            color: (resultsView.currentIndex === index)
                                ? "#45475a"
                                : appMouse.containsMouse ? "#313244" : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Image {
                                    source: Quickshell.iconPath(appItem.modelData.icon ?? "", "application-x-executable")
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    sourceSize: Qt.size(28, 28)
                                }

                                Text {
                                    text: appItem.modelData.name ?? ""
                                    color: "#cdd6f4"
                                    font.pixelSize: 14
                                    font.family: "Maple Mono"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: appItem.modelData.genericName ?? ""
                                    color: "#6c7086"
                                    font.pixelSize: 12
                                    font.family: "Maple Mono"
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 180
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(appItem.modelData)
                                onContainsMouseChanged: {
                                    if (containsMouse)
                                        resultsView.currentIndex = appItem.index;
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < root.filteredApps.length)
                                root.launch(root.filteredApps[currentIndex]);
                        }
                        Keys.onEscapePressed: root.toggle()
                        Keys.onUpPressed: {
                            if (currentIndex === 0)
                                searchInput.forceActiveFocus();
                            else
                                currentIndex--;
                        }
                        Keys.onPressed: (event) => {
                            if (!event.modifiers && event.text && event.text.length > 0) {
                                searchInput.forceActiveFocus();
                                searchInput.text += event.text;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
