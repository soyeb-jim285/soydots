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
    property int selectedAction: -1

    function toggle() {
        root.visible = !root.visible;
        if (root.visible) root.selectedAction = -1;
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggle(); }
    }

    GlobalShortcut {
        name: "powerMenuToggle"
        description: "Toggle power menu"
        onPressed: root.toggle()
    }

    property var actions: [
        { name: "Lock", icon: "\uf023", color: Theme.blue },
        { name: "Logout", icon: "\uf2f5", color: Theme.yellow },
        { name: "Suspend", icon: "\uf186", color: Theme.mauve },
        { name: "Hibernate", icon: "\uf0c2", color: Theme.teal },
        { name: "Reboot", icon: "\uf2f1", color: Theme.peach },
        { name: "Shutdown", icon: "\uf011", color: Theme.red }
    ]

    function executeAction(index) {
        root.visible = false;
        switch (index) {
            case 0: lockProc.running = true; break;
            case 1: logoutProc.running = true; break;
            case 2: suspendProc.running = true; break;
            case 3: hibernateProc.running = true; break;
            case 4: rebootProc.running = true; break;
            case 5: shutdownProc.running = true; break;
        }
    }

    Process { id: lockProc; command: ["quickshell", "msg", "lockscreen", "lock"] }
    Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"] }
    Process { id: suspendProc; command: ["systemctl", Config.idleHibernateEnabled ? "suspend-then-hibernate" : "suspend"] }
    Process { id: hibernateProc; command: ["systemctl", "hibernate"] }
    Process { id: rebootProc; command: ["systemctl", "reboot"] }
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }

    LazyLoader {
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-powermenu"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Backdrop with slow pulse
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
                    duration: 300
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Power menu panel
            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 420
                height: panelContent.implicitHeight + 48
                color: Theme.panelBg
                radius: 20
                border.color: Theme.surface1
                border.width: 1

                // Entrance: scale up with bounce + fade
                scale: 0.8
                opacity: 0
                transformOrigin: Item.Center

                NumberAnimation on scale {
                    from: 0.8; to: 1.0
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: 250
                    easing.type: Easing.OutCubic
                    running: true
                }

                // Subtle floating glow when an action is selected
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: root.selectedAction >= 0 ? 0.06 : 0
                    color: root.selectedAction >= 0 ? root.actions[root.selectedAction].color : "transparent"
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => {
                        root.selectedAction = -1;
                        event.accepted = true;
                    }
                }

                Item {
                    id: keyNav
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            root.toggle();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.selectedAction >= 0)
                                root.executeAction(root.selectedAction);
                        } else if (event.key === Qt.Key_Left) {
                            root.selectedAction = root.selectedAction <= 0 ? 5 : root.selectedAction - 1;
                        } else if (event.key === Qt.Key_Right) {
                            root.selectedAction = root.selectedAction >= 5 ? 0 : root.selectedAction + 1;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedAction = root.selectedAction < 3 ? root.selectedAction + 3 : root.selectedAction - 3;
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedAction = root.selectedAction >= 3 ? root.selectedAction - 3 : root.selectedAction + 3;
                        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
                            root.executeAction(event.key - Qt.Key_1);
                        }
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: panelContent
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18

                    // Title with icon
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Text {
                            text: "\uf011"
                            color: Theme.red
                            font.pixelSize: 16
                            font.family: Config.iconFont
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Power Menu"
                            color: Theme.text
                            font.pixelSize: 18
                            font.family: Config.fontFamily
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Action name display
                    Text {
                        text: root.selectedAction >= 0 ? root.actions[root.selectedAction].name : "Choose an action"
                        color: root.selectedAction >= 0 ? root.actions[root.selectedAction].color : Theme.subtext0
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Action grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 14
                        rowSpacing: 14

                        Repeater {
                            model: root.actions

                            Rectangle {
                                id: actionCard
                                required property var modelData
                                required property int index

                                property bool isSelected: root.selectedAction === index
                                property bool isHovered: cardMouse.containsMouse

                                Layout.fillWidth: true
                                height: 96
                                radius: 14
                                color: isSelected
                                    ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.15)
                                    : isHovered ? Theme.surface0 : "transparent"
                                border.color: isSelected
                                    ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.4)
                                    : isHovered ? Theme.surface1 : "transparent"
                                border.width: 1

                                // Staggered entrance animation
                                Component.onCompleted: entranceAnim.start()
                                transform: Translate { id: cardTranslate; y: 20 }
                                property real cardOpacity: 0

                                SequentialAnimation {
                                    id: entranceAnim
                                    PauseAnimation { duration: actionCard.index * 50 }
                                    ParallelAnimation {
                                        NumberAnimation { target: cardTranslate; property: "y"; from: 20; to: 0; duration: 300; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: actionCard; property: "cardOpacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
                                    }
                                }

                                opacity: cardOpacity

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                scale: 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 42; height: 42; radius: 21
                                        color: actionCard.isSelected
                                            ? modelData.color
                                            : actionCard.isHovered
                                                ? Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.15)
                                                : Theme.surface0

                                        Behavior on color { ColorAnimation { duration: 200 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.icon
                                            color: actionCard.isSelected ? Theme.crust : modelData.color
                                            font.pixelSize: 18
                                            font.family: Config.iconFont
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.name
                                        color: actionCard.isSelected ? modelData.color : Theme.text
                                        font.pixelSize: 11
                                        font.family: Config.fontFamily
                                        font.bold: actionCard.isSelected
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        actionCard.scale = 0.9;
                                        executeTimer.restart();
                                    }

                                    Timer {
                                        id: executeTimer
                                        interval: 150
                                        onTriggered: root.executeAction(actionCard.index)
                                    }

                                    onContainsMouseChanged: {
                                        if (containsMouse) {
                                            root.selectedAction = actionCard.index;
                                            actionCard.scale = 1.04;
                                        } else {
                                            actionCard.scale = 1.0;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Hint
                    Text {
                        text: "Enter to confirm \u2022 1-6 to quick select"
                        color: Theme.overlay0
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
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
