pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property bool locked: false
    property string password: ""
    property string status: "idle"  // idle, verifying, error, success
    property string errorMsg: ""
    property string timeText: ""
    property string dateText: ""
    property bool showPassword: false

    function lock() {
        root.locked = true;
        root.password = "";
        root.status = "idle";
        root.errorMsg = "";
        root.showPassword = false;
    }

    property string _user: Quickshell.env("USER") || "jim"

    function tryUnlock() {
        if (password.length === 0) return;
        root.status = "verifying";
        // Use sudo -S -k to validate password (-k clears cached creds, -S reads from stdin)
        authProc.command = ["bash", "-c", "echo '" + password.replace(/'/g, "'\\''") + "' | sudo -S -k true 2>/dev/null"];
        authProc.running = true;
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.lock(); }
    }

    // Clock timer
    Timer {
        interval: 1000
        running: root.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            root.timeText = Qt.formatDateTime(now, Config.lockTimeFormat);
            root.dateText = Qt.formatDateTime(now, Config.lockDateFormat);
        }
    }

    // Auth process
    Process {
        id: authProc
        command: ["true"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.status = "success";
                unlockTimer.restart();
            } else {
                root.status = "error";
                root.errorMsg = "Wrong password";
                root.password = "";
                errorResetTimer.restart();
            }
        }
    }

    Timer {
        id: unlockTimer
        interval: 400
        onTriggered: {
            sessionLock.locked = false;
            root.locked = false;
            root.password = "";
            root.status = "idle";
        }
    }

    Timer {
        id: errorResetTimer
        interval: 2000
        onTriggered: {
            root.status = "idle";
            root.errorMsg = "";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            // Handle keyboard input directly on the content item
            Item {
                id: keyHandler
                anchors.fill: parent
                focus: true

                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: (event) => {
                    if (root.status !== "idle") {
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.tryUnlock();
                    } else if (event.key === Qt.Key_Escape) {
                        root.password = "";
                    } else if (event.key === Qt.Key_Backspace) {
                        if (root.password.length > 0)
                            root.password = root.password.slice(0, -1);
                    } else if (event.text && event.text.length > 0 && !event.modifiers) {
                        root.password += event.text;
                    }
                    event.accepted = true;
                }
            }

            // Background
            Rectangle {
                anchors.fill: parent
                color: Config.crust

                // Subtle gradient overlay
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.3) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.4) }
                    }
                }
            }

            // Main content — centered vertically
            Item {
                anchors.centerIn: parent
                width: 400
                height: contentCol.implicitHeight

                ColumnLayout {
                    id: contentCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    // Clock — large, bold
                    Text {
                        id: clockText
                        text: root.timeText
                        color: Config.text
                        font.pixelSize: Config.lockClockSize
                        font.family: Config.fontFamily
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter

                        // Entrance: slide up + fade
                        opacity: 0
                        transform: Translate { id: clockSlide; y: 30 }
                        Component.onCompleted: { clockEntrance.start(); }
                        ParallelAnimation {
                            id: clockEntrance
                            NumberAnimation { target: clockText; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
                            NumberAnimation { target: clockSlide; property: "y"; from: 30; to: 0; duration: 600; easing.type: Easing.OutCubic }
                        }
                    }

                    // Date
                    Text {
                        id: dateText
                        visible: Config.lockShowDate
                        text: root.dateText
                        color: Config.subtext0
                        font.pixelSize: Config.lockDateSize
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4

                        opacity: 0
                        transform: Translate { id: dateSlide; y: 20 }
                        Component.onCompleted: { dateEntrance.start(); }
                        ParallelAnimation {
                            id: dateEntrance
                            PauseAnimation { duration: 100 }
                            NumberAnimation { target: dateText; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
                            NumberAnimation { target: dateSlide; property: "y"; from: 20; to: 0; duration: 500; easing.type: Easing.OutCubic }
                        }
                    }

                    // User icon circle
                    Rectangle {
                        id: userCircle
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 32
                        width: 80; height: 80; radius: 40
                        color: Config.surface0
                        border.color: root.status === "error" ? Config.red
                            : root.status === "success" ? Config.green
                            : root.status === "verifying" ? Config.blue
                            : Config.surface1
                        border.width: 2

                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        // Pulsing border on verifying
                        SequentialAnimation on border.width {
                            loops: Animation.Infinite
                            running: root.status === "verifying"
                            NumberAnimation { from: 2; to: 3; duration: 500; easing.type: Easing.InOutCubic }
                            NumberAnimation { from: 3; to: 2; duration: 500; easing.type: Easing.InOutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.status === "success" ? "\uf00c"
                                : root.status === "error" ? "\uf00d"
                                : "\uf007"
                            color: root.status === "success" ? Config.green
                                : root.status === "error" ? Config.red
                                : Config.text
                            font.pixelSize: 28
                            font.family: Config.iconFont

                            Behavior on color { ColorAnimation { duration: 300 } }

                            // Icon transition animation
                            scale: 1.0
                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: userCircle.children[0]; property: "scale"; to: 0.5; duration: 100; easing.type: Easing.InCubic }
                                    PropertyAction {}
                                    NumberAnimation { target: userCircle.children[0]; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 }
                                }
                            }
                        }

                        // Entrance animation
                        opacity: 0
                        scale: 0.6
                        Component.onCompleted: { userEntrance.start(); }
                        ParallelAnimation {
                            id: userEntrance
                            PauseAnimation { duration: 200 }
                            NumberAnimation { target: userCircle; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userCircle; property: "scale"; from: 0.6; to: 1.0; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                        }

                        // Shake animation on error
                        transform: Translate { id: userShake; x: 0 }
                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: userShake; property: "x"; to: 12; duration: 50; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userShake; property: "x"; to: -10; duration: 50; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userShake; property: "x"; to: 8; duration: 50; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userShake; property: "x"; to: -6; duration: 50; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userShake; property: "x"; to: 3; duration: 50; easing.type: Easing.OutCubic }
                            NumberAnimation { target: userShake; property: "x"; to: 0; duration: 50; easing.type: Easing.OutCubic }
                        }
                    }

                    // Username
                    Text {
                        text: Quickshell.env("USER") || "user"
                        color: Config.subtext1
                        font.pixelSize: 14
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10

                        opacity: 0
                        Component.onCompleted: { nameEntrance.start(); }
                        SequentialAnimation {
                            id: nameEntrance
                            PauseAnimation { duration: 300 }
                            NumberAnimation { target: parent; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    // Password field
                    Rectangle {
                        id: inputField
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        width: Config.lockInputWidth
                        height: Config.lockInputHeight
                        radius: Config.lockInputRadius
                        color: Config.surface0
                        border.color: root.status === "error" ? Config.red
                            : root.status === "success" ? Config.green
                            : keyHandler.activeFocus ? Config.blue
                            : Config.surface1
                        border.width: 1.5

                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        // Entrance: slide up + fade + scale
                        opacity: 0
                        scale: 0.9
                        transform: [
                            Translate { id: inputSlide; y: 15 },
                            Translate { id: inputShake; x: 0 }
                        ]
                        Component.onCompleted: { inputEntrance.start(); }
                        ParallelAnimation {
                            id: inputEntrance
                            PauseAnimation { duration: 400 }
                            NumberAnimation { target: inputField; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                            NumberAnimation { target: inputField; property: "scale"; from: 0.9; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
                            NumberAnimation { target: inputSlide; property: "y"; from: 15; to: 0; duration: 400; easing.type: Easing.OutCubic }
                        }

                        // Password dots — ListView with ScriptModel
                        ListView {
                            id: lockDotList
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -12 // offset for eye icon
                            property real fullWidth: count * (implicitHeight + spacing) - (count > 0 ? spacing : 0)
                            implicitHeight: 10
                            implicitWidth: fullWidth
                            width: Math.min(implicitWidth, inputField.width - 56)
                            height: implicitHeight
                            orientation: Qt.Horizontal
                            spacing: 6
                            interactive: false
                            visible: root.password.length > 0 && root.status === "idle" && !root.showPassword

                            Behavior on implicitWidth {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }

                            model: ScriptModel {
                                values: root.password.split("")
                            }

                            displaced: Transition {
                                NumberAnimation { properties: "x"; duration: 200; easing.type: Easing.OutCubic }
                            }

                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                                    NumberAnimation {
                                        property: "scale"; from: 0; to: 1; duration: 200
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                                    }
                                }
                            }

                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                                    NumberAnimation { property: "scale"; to: 0; duration: 150; easing.type: Easing.InCubic }
                                }
                            }

                            delegate: Rectangle {
                                width: 10; height: 10; radius: 5
                                color: root.status === "error" ? Config.red
                                    : root.status === "success" ? Config.green
                                    : Config.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        // Plain text password (shown when eye toggled)
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -12
                            text: root.password
                            color: Config.text
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            font.letterSpacing: 2
                            elide: Text.ElideRight
                            width: inputField.width - 56
                            horizontalAlignment: Text.AlignHCenter
                            visible: root.password.length > 0 && root.status === "idle" && root.showPassword
                            opacity: root.showPassword ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Eye toggle icon
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.showPassword ? "\uf06e" : "\uf070"  // eye / eye-slash
                            color: eyeMouse.containsMouse ? Config.text : Config.overlay0
                            font.pixelSize: 14
                            font.family: Config.iconFont
                            visible: root.password.length > 0 && root.status === "idle"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }

                        // Placeholder text
                        Text {
                            anchors.centerIn: parent
                            text: root.status === "verifying" ? "Verifying..."
                                : root.status === "error" ? root.errorMsg
                                : root.status === "success" ? "Welcome back!"
                                : "Enter password"
                            color: root.status === "error" ? Config.red
                                : root.status === "success" ? Config.green
                                : root.status === "verifying" ? Config.blue
                                : Config.overlay0
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            visible: root.password.length === 0 || root.status !== "idle"
                            opacity: root.status === "verifying" ? verifyPulse : (root.password.length > 0 && root.status === "idle" ? 0 : 1)
                            property real verifyPulse: 1.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            SequentialAnimation on verifyPulse {
                                loops: Animation.Infinite
                                running: root.status === "verifying"
                                NumberAnimation { from: 1; to: 0.4; duration: 600; easing.type: Easing.InOutCubic }
                                NumberAnimation { from: 0.4; to: 1; duration: 600; easing.type: Easing.InOutCubic }
                            }
                        }

                        // Click to refocus
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            onClicked: lockSurface.contentItem.forceActiveFocus()
                        }
                    }

                    // Status hint
                    Text {
                        id: hintText
                        text: root.status === "error" ? "Try again"
                            : root.status === "success" ? ""
                            : root.status === "verifying" ? ""
                            : root.password.length > 0 ? "Press Enter to unlock" : ""
                        color: Config.overlay0
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        opacity: text !== "" ? 1 : 0
                    }
                }
            }

            // Handle status changes
            Connections {
                target: root
                function onStatusChanged() {
                    if (root.status === "error") {
                        shakeAnim.start();
                        inputShakeAnim.start();
                    }
                    if (root.status === "success") {
                        successAnim.start();
                    }
                }
            }

            SequentialAnimation {
                id: inputShakeAnim
                NumberAnimation { target: inputShake; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: inputShake; property: "x"; to: -8; duration: 50 }
                NumberAnimation { target: inputShake; property: "x"; to: 6; duration: 50 }
                NumberAnimation { target: inputShake; property: "x"; to: -4; duration: 50 }
                NumberAnimation { target: inputShake; property: "x"; to: 2; duration: 50 }
                NumberAnimation { target: inputShake; property: "x"; to: 0; duration: 50 }
            }

            ParallelAnimation {
                id: successAnim
                NumberAnimation { target: inputField; property: "scale"; to: 0.95; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: inputField; property: "opacity"; to: 0.5; duration: 300; easing.type: Easing.OutCubic }
            }

            // Click anywhere to refocus key handler
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: keyHandler.forceActiveFocus()
            }
        }
    }
}
