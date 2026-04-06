pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "quill" as Quill

Scope {
    id: root

    property bool visible: false
    property string searchText: ""

    // Filter out system/network tools that shouldn't appear in a launcher
    property var hiddenApps: Config.launcherHiddenApps

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
            Quickshell.execDetached([Config.launcherTerminal].concat(app.command));
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
            WlrLayershell.namespace: "quickshell-launcher"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Background overlay fade — use color alpha (not element opacity)
            // so Hyprland ignore_alpha can distinguish backdrop from panel
            Rectangle {
                id: backdrop
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * Config.launcherBackdropOpacity)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on fadeIn {
                    from: 0; to: 1
                    duration: Config.animLauncherFadeDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Centered launcher container
            Rectangle {
                id: container
                anchors.centerIn: parent
                width: Config.launcherWidth
                height: Math.min(Config.launcherMaxHeight, searchBox.height + resultsView.contentHeight + 40)
                color: Theme.launcherBg
                radius: Config.launcherRadius
                border.color: Config.surface1
                border.width: 1

                // Entry animation
                scale: Config.animLauncherScaleFrom
                opacity: 0
                NumberAnimation on scale {
                    from: Config.animLauncherScaleFrom; to: 1.0
                    duration: Config.animLauncherScaleDuration
                    easing.type: Easing.OutBack
                    easing.overshoot: Config.animLauncherOvershoot
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: Config.animLauncherFadeDuration
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

                    Quill.TextField {
                        id: searchBox
                        Layout.fillWidth: true
                        variant: "filled"
                        placeholder: "Search apps..."
                        autoFocus: root.visible
                        onTextEdited: (val) => root.searchText = val

                        Component.onCompleted: {
                            inputItem.Keys.escapePressed.connect(() => root.toggle());
                            inputItem.Keys.downPressed.connect(() => resultsView.forceActiveFocus());
                            inputItem.Keys.returnPressed.connect(() => {
                                if (root.filteredApps.length > 0) root.launch(root.filteredApps[0]);
                            });
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
                        property bool keyboardNav: false
                        property real lastMouseX: -1
                        property real lastMouseY: -1

                        highlightFollowsCurrentItem: false
                        onCurrentIndexChanged: {
                            if (currentItem)
                                positionViewAtIndex(currentIndex, ListView.Contain);
                        }
                        highlight: Rectangle {
                            width: resultsView.width
                            height: Config.launcherItemHeight
                            radius: Config.launcherItemRadius
                            color: Config.surface1
                            y: resultsView.currentItem ? resultsView.currentItem.y : 0
                            z: 0
                            Behavior on y {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: appItem
                            required property var modelData
                            required property int index

                            width: resultsView.width
                            height: Config.launcherItemHeight
                            radius: Config.launcherItemRadius
                            color: "transparent"
                            z: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Image {
                                    property string _icon: appItem.modelData.icon ?? ""
                                    property string _primary: Quickshell.iconPath(_icon, "application-x-executable")
                                    property string _svgFallback: "file:///usr/share/icons/hicolor/scalable/apps/" + _icon + ".svg"
                                    property string _genericFallback: Quickshell.iconPath("application-x-executable", "")
                                    source: _primary !== "" ? _primary : _svgFallback
                                    Layout.preferredWidth: Config.launcherIconSize
                                    Layout.preferredHeight: Config.launcherIconSize
                                    sourceSize: Qt.size(Config.launcherIconSize, Config.launcherIconSize)
                                    onStatusChanged: {
                                        if (status === Image.Error && source !== _svgFallback && source !== _genericFallback)
                                            source = _svgFallback;
                                        else if (status === Image.Error && source === _svgFallback)
                                            source = _genericFallback;
                                    }
                                }

                                Text {
                                    text: appItem.modelData.name ?? ""
                                    color: Config.text
                                    font.pixelSize: 14
                                    font.family: Config.fontFamily
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: appItem.modelData.genericName ?? ""
                                    color: Config.overlay0
                                    font.pixelSize: 12
                                    font.family: Config.fontFamily
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 180
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(appItem.modelData)
                                onPositionChanged: (mouse) => {
                                    let screenX = appItem.mapToItem(null, mouse.x, mouse.y).x;
                                    let screenY = appItem.mapToItem(null, mouse.x, mouse.y).y;
                                    if (Math.abs(screenX - resultsView.lastMouseX) > 1 || Math.abs(screenY - resultsView.lastMouseY) > 1) {
                                        resultsView.lastMouseX = screenX;
                                        resultsView.lastMouseY = screenY;
                                        resultsView.keyboardNav = false;
                                        resultsView.currentIndex = appItem.index;
                                    }
                                }
                                onContainsMouseChanged: {
                                    if (containsMouse && !resultsView.keyboardNav)
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
                            keyboardNav = true;
                            if (currentIndex === 0)
                                searchBox.inputItem.forceActiveFocus();
                            else
                                currentIndex--;
                        }
                        Keys.onDownPressed: {
                            keyboardNav = true;
                            if (currentIndex < count - 1)
                                currentIndex++;
                        }
                        Keys.onPressed: (event) => {
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
