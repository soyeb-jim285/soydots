pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."

Item {
    id: root
    width: wsRow.implicitWidth
    height: parent?.height ?? Theme.barHeight

    property string variant: Config.workspaceVariant.toLowerCase()
    property bool isCapsule: variant === "capsule"
    property bool isRail: variant === "rail"
    property bool isDot: variant === "dot" || variant === "dots"

    function switchRelative(step) {
        let current = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
        let count = Math.max(1, Config.workspaceCount);
        if (current < 1 || current > count) current = 1;
        let next = ((current - 1 + step + count) % count) + 1;
        Hyprland.dispatch("workspace " + next);
    }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: root.isRail ? Math.max(3, Config.workspaceSpacing - 2) : Config.workspaceSpacing

        Repeater {
            model: Config.workspaceCount

            Item {
                id: wsButton
                required property int index
                property int wsId: index + 1
                property bool isFocused: Hyprland.focusedMonitor?.activeWorkspace?.id === wsId
                property bool hovered: wsMouse.containsMouse
                property bool isOccupied: {
                    let ws = Hyprland.workspaces.values;
                    for (let i = 0; i < ws.length; i++) {
                        if (ws[i].id === wsId) return true;
                    }
                    return false;
                }

                width: root.isCapsule ? Math.max(20, Config.workspaceDotHeight + 12)
                    : root.isRail ? (isFocused ? Math.max(22, Config.workspaceFocusedWidth - 4) : Math.max(10, Config.workspaceUnfocusedWidth))
                    : root.isDot ? Math.max(14, Config.workspaceDotHeight + 6)
                    : isFocused ? Config.workspaceFocusedWidth : Config.workspaceUnfocusedWidth
                height: root.height

                Rectangle {
                    id: capsuleBase
                    visible: root.isCapsule
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.max(18, Config.workspaceDotHeight + 8)
                    radius: height / 2
                    color: wsButton.isFocused
                        ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.20)
                        : wsButton.hovered ? Theme.surface1 : Theme.surface0
                    border.width: 1
                    border.color: wsButton.isFocused ? Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.55) : Theme.surface1

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDurationFast }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animDurationFast }
                    }
                }

                Rectangle {
                    id: dotHalo
                    visible: root.isDot && wsButton.isFocused
                    anchors.centerIn: parent
                    width: Config.workspaceDotHeight + 8
                    height: width
                    radius: width / 2
                    color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.35)
                }

                Rectangle {
                    id: marker
                    anchors.centerIn: parent
                    width: root.isCapsule ? (wsButton.isFocused ? Math.max(12, Config.workspaceDotHeight) : Math.max(6, Config.workspaceDotHeight - 4))
                        : root.isRail ? parent.width
                        : root.isDot ? (wsButton.isFocused ? Math.max(8, Config.workspaceDotHeight - 2) : Math.max(5, Config.workspaceDotHeight - 5))
                        : parent.width
                    height: root.isRail ? Math.max(4, Math.round(Config.workspaceDotHeight / 2))
                        : root.isDot || root.isCapsule ? width
                        : Config.workspaceDotHeight
                    radius: height / 2
                    color: wsButton.isFocused ? Theme.blue
                        : wsButton.isOccupied ? Theme.subtext0
                        : Theme.surface2
                    opacity: wsButton.isFocused ? 1.0
                        : wsButton.isOccupied ? 0.72
                        : wsButton.hovered ? 0.55
                        : 0.28

                    Behavior on width {
                        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                    }
                    Behavior on height {
                        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animDurationFast }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsButton.wsId)
                    onWheel: (event) => {
                        if (!Config.workspaceScrollEnabled) return;
                        let direction = event.angleDelta.y > 0 ? -1 : 1;
                        if (Config.workspaceScrollInvert) direction *= -1;
                        root.switchRelative(direction);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
