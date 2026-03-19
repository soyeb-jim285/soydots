pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."

Item {
    id: root
    width: wsRow.implicitWidth
    height: parent?.height ?? Theme.barHeight

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: Config.workspaceSpacing

        Repeater {
            model: Config.workspaceCount

            Rectangle {
                id: wsButton
                required property int index
                property int wsId: index + 1
                property bool isFocused: Hyprland.focusedMonitor?.activeWorkspace?.id === wsId
                property bool isOccupied: {
                    let ws = Hyprland.workspaces.values;
                    for (let i = 0; i < ws.length; i++) {
                        if (ws[i].id === wsId) return true;
                    }
                    return false;
                }

                width: isFocused ? Config.workspaceFocusedWidth : Config.workspaceUnfocusedWidth
                height: Config.workspaceDotHeight
                radius: Config.workspaceDotRadius
                color: isFocused ? Theme.blue
                    : isOccupied ? Theme.subtext0
                    : Theme.surface2
                opacity: isFocused ? 1.0 : isOccupied ? 0.8 : 0.3

                Behavior on width {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutBack; easing.overshoot: Config.workspaceOvershoot }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsButton.wsId)
                }
            }
        }
    }
}
