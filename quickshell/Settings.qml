pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "settings"
import "icons"

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
        { name: "Appearance", iconSource: "icons/IconPalette.qml", section: "appearance" },
        { name: "Bar", iconSource: "icons/IconPanelTop.qml", section: "bar" },
        { name: "Notifications", iconSource: "icons/IconBell.qml", section: "notifications" },
        { name: "Launcher", iconSource: "icons/IconRocket.qml", section: "launcher" },
        { name: "Clipboard", iconSource: "icons/IconClipboard.qml", section: "clipboard" },
        { name: "OSD", iconSource: "icons/IconSlidersH.qml", section: "osd" },
        { name: "Animations", iconSource: "icons/IconRefreshCw.qml", section: "animations" },
        { name: "Network", iconSource: "icons/IconWifi.qml", section: "network" },
        { name: "Calendar", iconSource: "icons/IconCalendar.qml", section: "calendar" },
        { name: "Battery", iconSource: "icons/IconBattery.qml", section: "battery" },
        { name: "Lock Screen", iconSource: "icons/IconLock.qml", section: "lockscreen" },
        { name: "Power & Idle", iconSource: "icons/IconZap.qml", section: "idle" },
        { name: "Integrations", iconSource: "icons/IconLink.qml", section: "hyprland" },
        { name: "Icon Gallery", iconSource: "icons/IconImage.qml", section: "icons" }
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
                            Row {
                                Layout.leftMargin: 12
                                Layout.bottomMargin: 12
                                spacing: 6
                                IconSettings { size: 16; color: Config.text }
                                Text { text: "Settings"; color: Config.text; font.pixelSize: 14; font.family: Config.fontFamily; font.bold: true }
                            }

                            // Scrollable nav items
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: navColumn.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: navColumn
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: root.pages

                                        Rectangle {
                                            required property var modelData
                                            required property int index

                                            width: navColumn.width
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

                                                Loader {
                                                    id: sidebarIconLoader
                                                    property int pageIndex: index
                                                    source: modelData.iconSource
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    onLoaded: {
                                                        item.size = 14;
                                                        item.color = Qt.binding(() => root.activePage === sidebarIconLoader.pageIndex ? Config.blue : Config.overlay0);
                                                    }
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
                                }
                            }

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
                                    IconUndo { size: 12; color: resetAllMouse.containsMouse ? Config.red : Config.overlay0 }
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
                                    IconUndo { size: 10; color: Config.overlay0 }
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
                                                 "IntegrationsPage", "IconGalleryPage"];
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
