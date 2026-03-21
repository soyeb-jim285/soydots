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
}
