pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import ".."
import "../icons"

Item {
    id: root
    width: mediaRow.implicitWidth + Theme.widgetPadding * 2
    height: parent?.height ?? Theme.barHeight

    property var player: Mpris.players.values?.[0] ?? null
    property bool hasPlayer: player !== null && player.playbackState !== MprisPlaybackState.Stopped
    property string trackInfo: {
        if (!hasPlayer) return "";
        let artist = player.trackArtist ?? "";
        let title = player.trackTitle ?? "";
        if (artist && title) return artist + " - " + title;
        return title || artist || "";
    }

    opacity: hasPlayer ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: mediaMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: Theme.fontSizeSmall; height: Theme.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter

            IconPlay {
                visible: root.player?.playbackState === MprisPlaybackState.Playing
                size: Theme.fontSizeSmall
                color: Theme.mauve
                anchors.centerIn: parent
            }
            IconPause {
                visible: root.player?.playbackState !== MprisPlaybackState.Playing
                size: Theme.fontSizeSmall
                color: Theme.mauve
                anchors.centerIn: parent
            }
        }

        Text {
            text: root.trackInfo
            color: Theme.subtext1
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, Config.mediaMaxWidth)
        }
    }

    MouseArea {
        id: mediaMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.player?.togglePlaying()
    }
}
