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
                    spacing: 18

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Text {
                            text: "Choose a connection animation"
                            color: Theme.text
                            font.pixelSize: 18
                            font.family: Theme.fontFamily
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.selected > 0 ? "Selected: " + root.animationName(root.selected) : "Click a spinner to select."
                            color: root.selected > 0 ? Theme.green : Theme.subtext1
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: Config.animPickerColumns
                        columnSpacing: Config.animPickerSpacing
                        rowSpacing: Config.animPickerSpacing

                        AnimCard {
                            num: 1
                            label: "Slow"
                            sel: root.selected
                            onPicked: root.selected = 1

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 1200
                                sweepDuration: 2200
                                growRatio: 0.35
                                maxSweep: 300
                                minSweep: 30
                                showHalo: false
                                radius: 18
                            }
                        }

                        AnimCard {
                            num: 2
                            label: "Gentle"
                            sel: root.selected
                            onPicked: root.selected = 2

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 900
                                sweepDuration: 1800
                                growRatio: 0.35
                                maxSweep: 300
                                minSweep: 30
                                showHalo: false
                                radius: 18
                            }
                        }

                        AnimCard {
                            num: 3
                            label: "Medium"
                            sel: root.selected
                            onPicked: root.selected = 3

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 750
                                sweepDuration: 1500
                                growRatio: 0.35
                                maxSweep: 300
                                minSweep: 30
                                showHalo: false
                                radius: 18
                            }
                        }

                        AnimCard {
                            num: 4
                            label: "Brisk"
                            sel: root.selected
                            onPicked: root.selected = 4

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 600
                                sweepDuration: 1200
                                growRatio: 0.35
                                maxSweep: 300
                                minSweep: 30
                                showHalo: false
                                radius: 18
                            }
                        }

                        AnimCard {
                            num: 5
                            label: "Fast"
                            sel: root.selected
                            onPicked: root.selected = 5

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 480
                                sweepDuration: 950
                                growRatio: 0.35
                                maxSweep: 280
                                minSweep: 25
                                showHalo: false
                                radius: 18
                            }
                        }

                        AnimCard {
                            num: 6
                            label: "Rapid"
                            sel: root.selected
                            onPicked: root.selected = 6

                            SpinnerPreview {
                                anchors.centerIn: parent
                                spinDuration: 380
                                sweepDuration: 750
                                growRatio: 0.33
                                maxSweep: 260
                                minSweep: 20
                                showHalo: false
                                radius: 18
                            }
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

    component SpinnerPreview: Item {
        id: spinner

        property int arcCount: 1
        property real radius: 22
        property real arcWidth: 2.8
        property int spinDuration: 700
        property int sweepDuration: 1400
        property real growRatio: 0.38
        property real centerSize: 28
        property bool showHalo: true
        property real minSweep: 20
        property real maxSweep: arcCount === 1 ? 270 : 130

        width: 72
        height: 72

        Item {
            id: rotor
            anchors.fill: parent
            transformOrigin: Item.Center

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: spinner.spinDuration
                loops: Animation.Infinite
                running: true
            }

            Repeater {
                model: spinner.arcCount

                delegate: Item {
                    id: arcDel
                    anchors.fill: parent

                    required property int index
                    property real sweep: spinner.minSweep
                    property real tailProgress: 0
                    property real cycleBase: 0
                    property real baseAngle: index * (360 / spinner.arcCount)
                    property real tailShift: spinner.maxSweep - spinner.minSweep

                    Shape {
                        anchors.fill: parent

                        ShapePath {
                            strokeColor: Theme.blue
                            strokeWidth: spinner.arcWidth
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: spinner.width / 2
                                centerY: spinner.height / 2
                                radiusX: spinner.radius
                                radiusY: spinner.radius
                                startAngle: arcDel.baseAngle + arcDel.cycleBase + arcDel.tailProgress * arcDel.tailShift
                                sweepAngle: arcDel.sweep
                            }
                        }
                    }

                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: true

                        ParallelAnimation {
                            NumberAnimation {
                                target: arcDel; property: "sweep"
                                from: spinner.minSweep; to: spinner.maxSweep
                                duration: Math.round(spinner.sweepDuration * spinner.growRatio)
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: arcDel; property: "tailProgress"
                                from: 0; to: 0
                                duration: Math.round(spinner.sweepDuration * spinner.growRatio)
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: arcDel; property: "sweep"
                                from: spinner.maxSweep; to: spinner.minSweep
                                duration: Math.round(spinner.sweepDuration * (1 - spinner.growRatio))
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                target: arcDel; property: "tailProgress"
                                from: 0; to: 1
                                duration: Math.round(spinner.sweepDuration * (1 - spinner.growRatio))
                                easing.type: Easing.InOutCubic
                            }
                        }

                        ScriptAction {
                            script: { arcDel.cycleBase += arcDel.tailShift; arcDel.tailProgress = 0; }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: spinner.showHalo
            width: spinner.centerSize + 10
            height: spinner.centerSize + 10
            radius: width / 2
            color: root.accent(0.05)
            border.color: root.accent(0.18)
            border.width: 1
        }

        Rectangle {
            anchors.centerIn: parent
            width: spinner.centerSize
            height: spinner.centerSize
            radius: width / 2
            color: Theme.crust
            border.color: root.accent(0.22)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf0c1"
                color: Theme.blue
                font.pixelSize: Math.round(spinner.centerSize * 0.42)
                font.family: Theme.iconFont
            }
        }
    }

    component AnimCard: Rectangle {
        id: card

        required property int num
        required property string label
        required property int sel

        signal picked()

        width: 164
        height: 162
        radius: 18
        color: sel === num ? root.accent(0.10) : cardMouse.containsMouse ? Theme.surface0 : "transparent"
        border.color: sel === num ? root.accent(0.35) : cardMouse.containsMouse ? Theme.surface1 : Theme.surface0
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        default property alias content: preview.data

        Rectangle {
            id: previewFrame
            width: 102
            height: 102
            radius: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            color: Theme.crust
            border.color: sel === num ? root.accent(0.22) : Theme.surface1
            border.width: 1
        }

        Item {
            id: preview
            anchors.centerIn: previewFrame
            width: 72
            height: 72
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            text: card.label
            color: card.sel === card.num ? Theme.blue : Theme.text
            font.pixelSize: 11
            font.family: Theme.fontFamily
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
