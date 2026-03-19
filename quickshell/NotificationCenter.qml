pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool visible: false
    required property var notifSource

    property bool clearingAll: false

    function toggle() {
        root.visible = !root.visible;
        if (root.visible) notifSource.resetUnread();
    }

    function animatedClearAll() {
        clearingAll = true;
        clearAllTimer.restart();
    }

    Timer {
        id: clearAllTimer
        interval: 300
        onTriggered: {
            root.notifSource.clearAll();
            root.clearingAll = false;
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggle(); }
    }

    Timer {
        interval: 30000; running: root.visible; repeat: true
        onTriggered: historyList.forceLayout()
    }

    LazyLoader {
        id: centerLoader
        active: root.visible

        PanelWindow {
            id: window
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent; color: "#000000"; opacity: 0
                MouseArea { anchors.fill: parent; onClicked: root.toggle() }
                NumberAnimation on opacity {
                    from: 0; to: 0.4; duration: 200
                    easing.type: Easing.OutCubic; running: true
                }
            }

            Rectangle {
                id: panel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 6
                anchors.rightMargin: 8
                anchors.bottomMargin: 8
                width: 300
                color: Theme.mantle
                radius: 14
                border.color: Theme.surface1
                border.width: 1

                NumberAnimation on anchors.rightMargin {
                    from: -320; to: 8; duration: 300
                    easing.type: Easing.OutCubic; running: true
                }
                opacity: 1
                NumberAnimation on opacity {
                    from: 0; to: 1; duration: 200
                    easing.type: Easing.OutCubic; running: true
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
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "\uf0f3"
                            color: Theme.blue
                            font.pixelSize: 13
                            font.family: Theme.iconFont
                        }
                        Text {
                            text: "Notifications"
                            color: Theme.text
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Count
                        Text {
                            visible: root.notifSource.history.length > 0
                            text: root.notifSource.history.length
                            color: Theme.overlay0
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                        }

                        // Clear all
                        Rectangle {
                            visible: root.notifSource.history.length > 0
                            width: 22; height: 22; radius: 11
                            color: clearMouse.containsMouse ? Theme.surface1 : Theme.surface0
                            Behavior on color { ColorAnimation { duration: 80 } }
                            Text {
                                anchors.centerIn: parent
                                text: "\uf1f8"  // trash
                                color: clearMouse.containsMouse ? Theme.red : Theme.overlay0
                                font.pixelSize: 10
                                font.family: Theme.iconFont
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            MouseArea {
                                id: clearMouse; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.animatedClearAll()
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Theme.surface0
                    }

                    // Empty state
                    Item {
                        visible: root.notifSource.history.length === 0
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uf0f3"
                                color: Theme.surface2
                                font.pixelSize: 28; font.family: Theme.iconFont
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "All clear"
                                color: Theme.overlay0
                                font.pixelSize: 11; font.family: Theme.fontFamily
                            }
                        }
                    }

                    // History list
                    ListView {
                        id: historyList
                        visible: root.notifSource.history.length > 0
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 2
                        model: root.notifSource.history

                        delegate: Rectangle {
                            id: histItem
                            required property var modelData
                            required property int index

                            width: historyList.width
                            height: histRow.implicitHeight + 12
                            radius: 8
                            color: histMouse.containsMouse ? Theme.surface0 : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }

                            property bool dying: false
                            property bool gone: dying || root.clearingAll
                            x: gone ? width : 0
                            opacity: gone ? 0 : 1
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            function dismiss() {
                                dying = true;
                                dismissTimer.restart();
                            }
                            Timer {
                                id: dismissTimer
                                interval: 300
                                onTriggered: root.notifSource.dismissHistory(histItem.index)
                            }

                            Row {
                                id: histRow
                                anchors.left: parent.left
                                anchors.right: histDismiss.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 8

                                // Urgency dot
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6; height: 6; radius: 3
                                    color: root.notifSource.urgencyColor(histItem.modelData.urgency)
                                }

                                Column {
                                    width: parent.width - 18
                                    spacing: 1

                                    // Summary + time
                                    Row {
                                        width: parent.width; spacing: 4

                                        Text {
                                            text: histItem.modelData.summary || histItem.modelData.appName || "Notification"
                                            color: Theme.text
                                            font.pixelSize: 11
                                            font.family: Theme.fontFamily
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width - timeText.implicitWidth - 8
                                        }

                                        Text {
                                            id: timeText
                                            text: root.notifSource.timeAgo(histItem.modelData.time)
                                            color: Theme.surface2
                                            font.pixelSize: 9
                                            font.family: Theme.fontFamily
                                        }
                                    }

                                    // Body
                                    Text {
                                        visible: text !== ""
                                        text: histItem.modelData.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                                        color: Theme.subtext0
                                        font.pixelSize: 10
                                        font.family: Theme.fontFamily
                                        width: parent.width
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            // Dismiss button
                            Rectangle {
                                id: histDismiss
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 6
                                width: 24; height: 24; radius: 12
                                visible: histMouse.containsMouse || histDismissMouse.containsMouse
                                color: histDismissMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: histDismissMouse.containsMouse ? Theme.red : Theme.overlay0
                                    font.pixelSize: 11; font.family: Theme.iconFont
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                                MouseArea {
                                    id: histDismissMouse; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: histItem.dismiss()
                                }
                            }

                            MouseArea {
                                id: histMouse; anchors.fill: parent
                                hoverEnabled: true; z: -1
                            }
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    onActivated: root.toggle()
                }
            }
        }
    }
}
