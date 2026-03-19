pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import ".."

PopupWindow {
    id: popup
    implicitWidth: Config.mediaPopupWidth
    implicitHeight: contentCol.implicitHeight + 32
    color: "transparent"

    property var player: Mpris.players.values?.[0] ?? null

    Rectangle {
        anchors.fill: parent
        color: Theme.panelBg
        radius: Config.mediaPopupRadius
        border.color: Theme.surface1
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: popup.player?.trackTitle ?? "No track"
                color: Theme.text
                font.pixelSize: 14
                font.family: Theme.fontFamily
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: popup.player?.trackArtist ?? ""
                color: Theme.subtext0
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Text {
                    text: "\uf048"
                    color: prevMouse.containsMouse ? Theme.text : Theme.subtext0
                    font.pixelSize: 20
                    font.family: Theme.iconFont
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player?.previous()
                    }
                }

                Text {
                    text: popup.player?.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b"
                    color: playMouse.containsMouse ? Theme.mauve : Theme.text
                    font.pixelSize: 24
                    font.family: Theme.iconFont
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player?.togglePlaying()
                    }
                }

                Text {
                    text: "\uf051"
                    color: nextMouse.containsMouse ? Theme.text : Theme.subtext0
                    font.pixelSize: 20
                    font.family: Theme.iconFont
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.player?.next()
                    }
                }
            }
        }
    }
}
