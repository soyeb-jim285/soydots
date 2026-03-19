import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Hyprland"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    Text {
        text: "Changes apply live via hyprctl. Colors sync from the theme palette."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Sync Border Colors"; section: "hyprland"; key: "syncColors"; value: Config.hyprSyncColors }

    SliderSetting { label: "Gaps Inner"; section: "hyprland"; key: "gapsIn"; value: Config.hyprGapsIn; from: 0; to: 20 }
    SliderSetting { label: "Gaps Outer"; section: "hyprland"; key: "gapsOut"; value: Config.hyprGapsOut; from: 0; to: 30 }
    SliderSetting { label: "Border Size"; section: "hyprland"; key: "borderSize"; value: Config.hyprBorderSize; from: 0; to: 6 }
    SliderSetting { label: "Rounding"; section: "hyprland"; key: "rounding"; value: Config.hyprRounding; from: 0; to: 24 }

    // Color preview
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 4; spacing: 8

        Text { text: "Active border:"; color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily }
        Rectangle {
            width: 60; height: 4; radius: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Config.blue }
                GradientStop { position: 1; color: Config.lavender }
            }
        }

        Text { text: "Inactive:"; color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily }
        Rectangle { width: 40; height: 4; radius: 2; color: Config.surface2 }
    }

    // Blur
    Text { text: "Blur"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    ToggleSetting { label: "Enable Blur"; section: "hyprland"; key: "blurEnabled"; value: Config.hyprBlurEnabled }
    SliderSetting { label: "Blur Size"; section: "hyprland"; key: "blurSize"; value: Config.hyprBlurSize; from: 1; to: 20; visible: Config.hyprBlurEnabled }
    SliderSetting { label: "Blur Passes"; section: "hyprland"; key: "blurPasses"; value: Config.hyprBlurPasses; from: 1; to: 6; visible: Config.hyprBlurEnabled }
    SliderSetting { label: "Vibrancy"; section: "hyprland"; key: "blurVibrancy"; value: Config.hyprBlurVibrancy; from: 0; to: 1.0; decimals: 2; stepSize: 0.01; visible: Config.hyprBlurEnabled }
    ToggleSetting { label: "X-Ray"; section: "hyprland"; key: "blurXray"; value: Config.hyprBlurXray; visible: Config.hyprBlurEnabled }

    // Separator
    Rectangle { Layout.fillWidth: true; height: 1; color: Config.surface0; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text { text: "Kitty Terminal"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    Text {
        text: "Writes current-theme.conf and reloads kitty colors live. Requires kitty remote control (allow_remote_control in kitty.conf)."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Sync Terminal Colors"; section: "kitty"; key: "syncColors"; value: Config.kittySyncColors }
    SliderSetting { label: "Background Opacity"; section: "kitty"; key: "opacity"; value: Config.kittyOpacity; from: 0.1; to: 1.0; decimals: 2; stepSize: 0.05 }

    // Color preview
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        height: 60; radius: 8
        color: Config.base
        opacity: Config.kittyOpacity
        border.color: Config.surface1; border.width: 1

        Column {
            anchors.centerIn: parent; spacing: 2

            Row {
                spacing: 8
                Text { text: "~$"; color: Config.green; font.pixelSize: 11; font.family: Config.fontFamily; font.bold: true }
                Text { text: "echo"; color: Config.blue; font.pixelSize: 11; font.family: Config.fontFamily }
                Text { text: "\"hello\""; color: Config.yellow; font.pixelSize: 11; font.family: Config.fontFamily }
            }

            Row {
                spacing: 4
                Repeater {
                    model: [Config.red, Config.green, Config.yellow, Config.blue, Config.mauve, Config.pink, Config.teal, Config.peach]
                    Rectangle {
                        required property string modelData
                        width: 16; height: 8; radius: 2; color: modelData
                    }
                }
            }
        }
    }
}
