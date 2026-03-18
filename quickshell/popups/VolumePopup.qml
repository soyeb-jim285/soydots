pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: popup
    implicitWidth: 260
    implicitHeight: contentCol.implicitHeight + 32
    color: "transparent"

    property var sink: null
    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        radius: 12
        border.color: Theme.surface1
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Volume"
                color: Theme.text
                font.pixelSize: 14
                font.family: Theme.fontFamily
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: popup.muted ? "\uf6a9" : "\uf028"
                    color: popup.muted ? Theme.red : Theme.blue
                    font.pixelSize: 18
                    font.family: Theme.iconFont

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (popup.sink?.audio)
                                popup.sink.audio.muted = !popup.sink.audio.muted;
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.surface1
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * popup.volume
                        height: 4
                        radius: 2
                        color: popup.muted ? Theme.red : Theme.blue
                        Behavior on width { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * popup.volume - 7
                        width: 14
                        height: 14
                        radius: 7
                        color: popup.muted ? Theme.red : Theme.blue
                        Behavior on x { NumberAnimation { duration: Theme.animDurationFast } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (event) => {
                            if (pressed && popup.sink?.audio)
                                popup.sink.audio.volume = Math.max(0, Math.min(1, event.x / width));
                        }
                        onClicked: (event) => {
                            if (popup.sink?.audio)
                                popup.sink.audio.volume = Math.max(0, Math.min(1, event.x / width));
                        }
                    }
                }

                Text {
                    text: Math.round(popup.volume * 100) + "%"
                    color: Theme.text
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    Layout.minimumWidth: 32
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
