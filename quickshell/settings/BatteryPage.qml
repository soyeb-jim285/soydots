import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Battery Thresholds"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    Text {
        text: "Battery icon color changes at these percentage levels."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    SliderSetting { label: "Green Above (%)"; section: "battery"; key: "greenThreshold"; value: Config.batteryGreenThreshold; from: 30; to: 90 }
    SliderSetting { label: "Yellow Above (%)"; section: "battery"; key: "yellowThreshold"; value: Config.batteryYellowThreshold; from: 5; to: 50 }

    // Preview
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 12

        Text { text: "Preview:"; color: Config.subtext0; font.pixelSize: 11; font.family: Config.fontFamily }

        Row {
            spacing: 16
            Row {
                spacing: 4
                Rectangle { width: 12; height: 12; radius: 6; color: Config.green }
                Text { text: "> " + Config.batteryGreenThreshold + "%"; color: Config.text; font.pixelSize: 10; font.family: Config.fontFamily }
            }
            Row {
                spacing: 4
                Rectangle { width: 12; height: 12; radius: 6; color: Config.yellow }
                Text { text: Config.batteryYellowThreshold + "-" + Config.batteryGreenThreshold + "%"; color: Config.text; font.pixelSize: 10; font.family: Config.fontFamily }
            }
            Row {
                spacing: 4
                Rectangle { width: 12; height: 12; radius: 6; color: Config.red }
                Text { text: "< " + Config.batteryYellowThreshold + "%"; color: Config.text; font.pixelSize: 10; font.family: Config.fontFamily }
            }
        }
    }

    Text { text: "Night Light"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 16; Layout.bottomMargin: 4 }

    SliderSetting { label: "Temperature (K)"; section: "nightlight"; key: "temperature"; value: Config.nightLightTemp; from: 1000; to: 6500; stepSize: 100 }

    // Temperature preview
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 4; spacing: 8

        Text { text: "Preview:"; color: Config.subtext0; font.pixelSize: 11; font.family: Config.fontFamily }

        Rectangle {
            width: 80; height: 20; radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ff8a00" }
                GradientStop { position: 0.5; color: "#ffc864" }
                GradientStop { position: 1.0; color: "#ffffff" }
            }

            Rectangle {
                x: parent.width * Math.max(0, Math.min(1, (Config.nightLightTemp - 1000) / 5500)) - 2
                y: -2; width: 4; height: 24; radius: 2
                color: Config.text
            }
        }

        Text { text: Config.nightLightTemp + "K"; color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily }
    }
}
