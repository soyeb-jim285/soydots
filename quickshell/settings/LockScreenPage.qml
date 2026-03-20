import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Clock"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Clock Size"; section: "lockscreen"; key: "clockSize"; value: Config.lockClockSize; from: 32; to: 120 }
    SliderSetting { label: "Date Size"; section: "lockscreen"; key: "dateSize"; value: Config.lockDateSize; from: 10; to: 32 }
    ToggleSetting { label: "Show Date"; section: "lockscreen"; key: "showDate"; value: Config.lockShowDate }
    TextSetting { label: "Time Format"; section: "lockscreen"; key: "timeFormat"; value: Config.lockTimeFormat }
    TextSetting { label: "Date Format"; section: "lockscreen"; key: "dateFormat"; value: Config.lockDateFormat }

    Text { text: "Password Input"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Input Width"; section: "lockscreen"; key: "inputWidth"; value: Config.lockInputWidth; from: 200; to: 500 }
    SliderSetting { label: "Input Height"; section: "lockscreen"; key: "inputHeight"; value: Config.lockInputHeight; from: 32; to: 64 }
    SliderSetting { label: "Input Radius"; section: "lockscreen"; key: "inputRadius"; value: Config.lockInputRadius; from: 0; to: 32 }

    // Test button
    Text { text: "Test"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Rectangle {
        Layout.fillWidth: true
        height: 36; radius: 8
        color: testMouse.containsMouse ? Config.surface0 : "transparent"
        border.color: Config.surface1; border.width: 1
        Behavior on color { ColorAnimation { duration: 80 } }

        Row {
            anchors.centerIn: parent; spacing: 8
            Text { text: "\uf023"; color: Config.blue; font.pixelSize: 14; font.family: Config.iconFont }
            Text { text: "Test Lock Screen"; color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily }
        }

        MouseArea {
            id: testMouse
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: testLockProc.running = true
        }

        Process {
            id: testLockProc
            command: ["quickshell", "msg", "lockscreen", "lock"]
        }
    }
}
