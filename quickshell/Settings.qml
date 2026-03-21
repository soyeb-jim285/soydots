pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "settings"

Scope {
    id: root

    property bool visible: false
    property int activePage: 0

    function toggle() {
        root.visible = !root.visible;
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggle settings window"
        onPressed: root.toggle()
    }

    property var pages: [
        { name: "Appearance", icon: "\uf53f", section: "appearance" },
        { name: "Bar", icon: "\uf0c9", section: "bar" },
        { name: "Notifications", icon: "\uf0f3", section: "notifications" },
        { name: "Launcher", icon: "\uf135", section: "launcher" },
        { name: "Clipboard", icon: "\uf328", section: "clipboard" },
        { name: "OSD", icon: "\uf26c", section: "osd" },
        { name: "Animations", icon: "\uf021", section: "animations" },
        { name: "Network", icon: "\uf1eb", section: "network" },
        { name: "Calendar", icon: "\uf073", section: "calendar" },
        { name: "Battery", icon: "\uf240", section: "battery" },
        { name: "Lock Screen", icon: "\uf023", section: "lockscreen" },
        { name: "Power & Idle", icon: "\uf0e7", section: "idle" },
        { name: "Integrations", icon: "\uf0c1", section: "hyprland" }
    ]

    LazyLoader {
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-settings"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            // Backdrop — color alpha so blur ignore_alpha works
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
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Settings panel
            Rectangle {
                id: settingsPanel
                anchors.centerIn: parent
                width: 740
                height: 560
                color: Theme.settingsBg
                radius: 20
                border.color: Config.surface1
                border.width: 1

                scale: 0.92
                opacity: 0

                NumberAnimation on scale {
                    from: 0.92; to: 1.0
                    duration: 250
                    easing.type: Easing.OutCubic
                    running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                    running: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Sidebar
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 180
                        color: Config.crust
                        radius: 20

                        // Cover right-side radius
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 20
                            color: parent.color
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.topMargin: 16
                            spacing: 2

                            // Header
                            Text {
                                text: "\uf013  Settings"
                                color: Config.text
                                font.pixelSize: 16
                                font.family: Config.fontFamily
                                font.bold: true
                                Layout.leftMargin: 12
                                Layout.bottomMargin: 12
                            }

                            // Nav items
                            Repeater {
                                model: root.pages

                                Rectangle {
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: root.activePage === index
                                        ? Qt.rgba(Config.blue.r, Config.blue.g, Config.blue.b, 0.15)
                                        : navMouse.containsMouse ? Config.surface0 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.icon
                                            color: root.activePage === index ? Config.blue : Config.overlay0
                                            font.pixelSize: 14
                                            font.family: Config.iconFont
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            color: root.activePage === index ? Config.blue : Config.text
                                            font.pixelSize: 12
                                            font.family: Config.fontFamily
                                            font.bold: root.activePage === index
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activePage = index
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Reset all button
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: resetAllMouse.containsMouse ? Qt.rgba(Config.red.r, Config.red.g, Config.red.b, 0.15) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: "\uf2ea"
                                        color: resetAllMouse.containsMouse ? Config.red : Config.overlay0
                                        font.pixelSize: 12; font.family: Config.iconFont
                                    }
                                    Text {
                                        text: "Reset All"
                                        color: resetAllMouse.containsMouse ? Config.red : Config.subtext0
                                        font.pixelSize: 11; font.family: Config.fontFamily
                                    }
                                }

                                MouseArea {
                                    id: resetAllMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.resetAll()
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: Config.surface0
                    }

                    // Content area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Page header with reset button
                        RowLayout {
                            id: pageHeader
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 20
                            anchors.bottomMargin: 0

                            Text {
                                text: root.pages[root.activePage].name
                                color: Config.text
                                font.pixelSize: 18
                                font.family: Config.fontFamily
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: resetRow.implicitWidth + 16
                                height: 28
                                radius: 6
                                color: resetMouse.containsMouse ? Config.surface0 : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Row {
                                    id: resetRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "\uf2ea"
                                        color: Config.overlay0
                                        font.pixelSize: 10; font.family: Config.iconFont
                                    }
                                    Text {
                                        text: "Reset Section"
                                        color: Config.subtext0
                                        font.pixelSize: 10; font.family: Config.fontFamily
                                    }
                                }

                                MouseArea {
                                    id: resetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.resetSection(root.pages[root.activePage].section)
                                }
                            }
                        }

                        // Page content
                        Flickable {
                            anchors.top: pageHeader.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 20
                            anchors.topMargin: 12
                            contentHeight: pageLoader.item?.implicitHeight ?? 0
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: pageLoader
                                width: parent.width
                                source: {
                                    let names = ["AppearancePage", "BarPage", "NotificationsPage",
                                                 "LauncherPage", "ClipboardPage", "OsdPage",
                                                 "AnimationsPage", "NetworkPage", "CalendarPage",
                                                 "BatteryPage", "LockScreenPage", "PowerIdlePage",
                                                 "IntegrationsPage"];
                                    return "settings/" + names[root.activePage] + ".qml";
                                }
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
