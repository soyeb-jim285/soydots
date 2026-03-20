pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Scope {
    id: root

    property bool visible: false
    property int selected: Config.animPickerSelectedPreset

    function toggle() {
        root.visible = !root.visible;
    }

    function accent(alpha) {
        return Qt.rgba(137 / 255, 180 / 255, 250 / 255, alpha);
    }

    function animationName(index) {
        switch (index) {
        case 1:
            return "Slow";
        case 2:
            return "Gentle";
        case 3:
            return "Medium";
        case 4:
            return "Brisk";
        case 5:
            return "Fast";
        case 6:
            return "Rapid";
        default:
            return "";
        }
    }

    IpcHandler {
        target: "animpicker"

        function toggle(): void {
            root.toggle();
        }
    }

    LazyLoader {
        active: root.visible

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-animpicker"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * 0.25)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on fadeIn {
                    from: 0
                    to: 1
                    duration: Config.animPickerFadeDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: Config.animPickerWidth
                height: Config.animPickerHeight
                radius: Config.animPickerRadius
                color: Theme.animPickerBg
                border.color: Theme.surface1
                border.width: 1

                scale: Config.animPickerScaleFrom
                opacity: 0

                NumberAnimation on scale {
                    from: Config.animPickerScaleFrom
                    to: 1.0; duration: Config.animPickerScaleDuration
                    easing.type: Easing.OutCubic
                    running: true
                }

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: Config.animPickerFadeDuration
                    easing.type: Easing.OutCubic
                    running: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    Text {
                        text: "Password Input Style"
                        color: Theme.text
                        font.pixelSize: 18; font.family: Theme.fontFamily; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.selected > 0 ? "Selected: " + root.animationName(root.selected) : "Click a style to select, then type to preview."
                        color: root.selected > 0 ? Theme.green : Theme.subtext1
                        font.pixelSize: 11; font.family: Theme.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Shared buffer for all variants
                    property string sharedBuffer: ""

                    Item {
                        id: sharedKeyHandler
                        focus: true
                        Layout.preferredWidth: 0; Layout.preferredHeight: 0
                        Component.onCompleted: forceActiveFocus()
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                parent.sharedBuffer = "";
                            } else if (event.key === Qt.Key_Backspace) {
                                if (parent.sharedBuffer.length > 0)
                                    parent.sharedBuffer = parent.sharedBuffer.slice(0, -1);
                            } else if (event.text && event.text.length > 0 && !event.modifiers) {
                                parent.sharedBuffer += event.text;
                            }
                            event.accepted = true;
                        }
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3
                        columnSpacing: 14
                        rowSpacing: 14

                        // Style 1: Circle dots, tight spacing, bouncy
                        DotStyleCard {
                            num: 1; label: "Bouncy"; sel: root.selected; onPicked: root.selected = 1
                            buffer: parent.parent.sharedBuffer
                            dotSize: 10; dotRadius: 5; dotSpacing: 6
                            addDuration: 200; removeDuration: 150; slideDuration: 200
                            addCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                        }

                        // Style 2: Circle dots, wide spacing, gentle
                        DotStyleCard {
                            num: 2; label: "Gentle"; sel: root.selected; onPicked: root.selected = 2
                            buffer: parent.parent.sharedBuffer
                            dotSize: 10; dotRadius: 5; dotSpacing: 12
                            addDuration: 350; removeDuration: 250; slideDuration: 300
                            addCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }

                        // Style 3: Square dots, snappy
                        DotStyleCard {
                            num: 3; label: "Square"; sel: root.selected; onPicked: root.selected = 3
                            buffer: parent.parent.sharedBuffer
                            dotSize: 9; dotRadius: 2; dotSpacing: 6
                            addDuration: 120; removeDuration: 100; slideDuration: 150
                            addCurve: [0.2, 0, 0, 1, 1, 1]
                        }

                        // Style 4: Large round, springy
                        DotStyleCard {
                            num: 4; label: "Springy"; sel: root.selected; onPicked: root.selected = 4
                            buffer: parent.parent.sharedBuffer
                            dotSize: 12; dotRadius: 6; dotSpacing: 8
                            addDuration: 250; removeDuration: 180; slideDuration: 250
                            addCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
                        }

                        // Style 5: Pill-shaped, smooth
                        DotStyleCard {
                            num: 5; label: "Pill"; sel: root.selected; onPicked: root.selected = 5
                            buffer: parent.parent.sharedBuffer
                            dotSize: 10; dotRadius: 3; dotSpacing: 4; dotWidth: 16
                            addDuration: 200; removeDuration: 150; slideDuration: 200
                            addCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                        }

                        // Style 6: Tiny dots, rapid
                        DotStyleCard {
                            num: 6; label: "Minimal"; sel: root.selected; onPicked: root.selected = 6
                            buffer: parent.parent.sharedBuffer
                            dotSize: 7; dotRadius: 3.5; dotSpacing: 10
                            addDuration: 100; removeDuration: 80; slideDuration: 120
                            addCurve: [0.2, 0, 0, 1, 1, 1]
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    onActivated: root.toggle()
                }
            }
        }
    }

    component DotStyleCard: Rectangle {
        id: card

        required property int num
        required property string label
        required property int sel
        required property string buffer

        property int dotSize: 10
        property real dotRadius: 5
        property int dotSpacing: 8
        property int dotWidth: dotSize  // allow non-square (pill)
        property int addDuration: 200
        property int removeDuration: 150
        property int slideDuration: 200
        property var addCurve: [0.34, 1.56, 0.64, 1, 1, 1]

        signal picked()

        width: 190
        height: 100
        radius: 14
        color: sel === num ? root.accent(0.10) : cardMouse.containsMouse ? Theme.surface0 : "transparent"
        border.color: sel === num ? root.accent(0.35) : cardMouse.containsMouse ? Theme.surface1 : Theme.surface0
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Dot preview area
        Rectangle {
            id: dotFrame
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: parent.width - 24
            height: 46
            radius: 10
            color: Config.surface0
            border.color: Config.surface1; border.width: 1

            ListView {
                anchors.centerIn: parent
                property real fullWidth: count * (card.dotWidth + spacing) - (count > 0 ? spacing : 0)
                implicitHeight: card.dotSize
                implicitWidth: fullWidth
                width: Math.min(implicitWidth, dotFrame.width - 16)
                height: implicitHeight
                orientation: Qt.Horizontal
                spacing: card.dotSpacing
                interactive: false

                Behavior on implicitWidth {
                    NumberAnimation { duration: card.slideDuration; easing.type: Easing.OutCubic }
                }

                model: ScriptModel { values: card.buffer.split("") }

                displaced: Transition {
                    NumberAnimation { properties: "x"; duration: card.slideDuration; easing.type: Easing.OutCubic }
                }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: card.addDuration; easing.type: Easing.OutCubic }
                        NumberAnimation {
                            property: "scale"; from: 0; to: 1; duration: card.addDuration
                            easing.type: Easing.BezierSpline; easing.bezierCurve: card.addCurve
                        }
                    }
                }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: card.removeDuration; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; to: 0; duration: card.removeDuration; easing.type: Easing.InCubic }
                    }
                }

                delegate: Rectangle {
                    width: card.dotWidth; height: card.dotSize
                    radius: card.dotRadius
                    color: Config.text
                }
            }

            // Placeholder
            Text {
                anchors.centerIn: parent
                text: "type..."
                color: Config.overlay0
                font.pixelSize: 10; font.family: Config.fontFamily
                visible: card.buffer.length === 0
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: card.label
            color: card.sel === card.num ? Theme.blue : Theme.text
            font.pixelSize: 11; font.family: Theme.fontFamily
            font.bold: card.sel === card.num
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.picked()
        }
    }
}
