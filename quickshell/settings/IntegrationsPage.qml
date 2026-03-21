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

    // Separator
    Rectangle { Layout.fillWidth: true; height: 1; color: Config.surface0; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text { text: "Tmux"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    Text {
        text: "Syncs Catppuccin theme colors to tmux. Overwrites the catppuccin-mocha.tmuxtheme and reloads the tmux config."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Sync Tmux Colors"; section: "tmux"; key: "syncColors"; value: Config.tmuxSyncColors }
    ToggleSetting { label: "Status Bar at Bottom"; section: "tmux"; key: "statusBottom"; value: Config.tmuxStatusBottom }
    ToggleSetting { label: "Pill-shaped Separators"; section: "tmux"; key: "pillShape"; value: Config.tmuxPillShape }

    Rectangle { Layout.fillWidth: true; height: 1; color: Config.surface0; Layout.topMargin: 8; Layout.bottomMargin: 4 }

    Text { text: "Status Modules"; color: Config.blue; font.pixelSize: 11; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 2 }

    Text {
        text: "Toggle modules in the tmux status bar. CPU/Temp require lm-sensors, GPU requires nvidia-smi."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Clock"; section: "tmux"; key: "showClock"; value: Config.tmuxShowClock }
    TextSetting { label: "Clock Format"; section: "tmux"; key: "clockFormat"; value: Config.tmuxClockFormat; visible: Config.tmuxShowClock }
    ToggleSetting { label: "CPU Utilization"; section: "tmux"; key: "showCpu"; value: Config.tmuxShowCpu }
    ToggleSetting { label: "GPU Utilization"; section: "tmux"; key: "showGpu"; value: Config.tmuxShowGpu }
    ToggleSetting { label: "Temperature"; section: "tmux"; key: "showTemp"; value: Config.tmuxShowTemp }

    // Tmux status bar preview
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        height: 32; radius: 8
        color: Config.base
        border.color: Config.surface1; border.width: 1

        property int shapeRadius: Config.tmuxPillShape ? 10 : 2

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 12
            spacing: 6

            // Session — icon filled, text on gray
            Row {
                spacing: 0
                Rectangle {
                    width: sessIcon.implicitWidth + 10; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.green
                    // Cover right rounding
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: sessIcon; anchors.centerIn: parent; text: " "; color: Config.base; font.pixelSize: 10; font.family: Config.fontFamily; font.bold: true }
                }
                Rectangle {
                    width: sessText.implicitWidth + 10; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: sessText; anchors.centerIn: parent; text: "0"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // Window (inactive) — number + text, both gray
            Row {
                spacing: 0
                Rectangle {
                    width: win1Num.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.surface0
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: win1Num; anchors.centerIn: parent; text: "bash"; color: Config.overlay0; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: win1Text.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: win1Text; anchors.centerIn: parent; text: "1"; color: Config.overlay0; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // Window (active) — text on gray, number colored
            Row {
                spacing: 0
                Rectangle {
                    width: win2Name.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.surface0
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: win2Name; anchors.centerIn: parent; text: "bash"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: win2Num.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius
                    color: Config.blue
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: win2Num; anchors.centerIn: parent; text: "2"; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily; font.bold: true }
                }
            }
        }

        // Right side — status modules
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right; anchors.rightMargin: 12
            spacing: 4

            // Directory — icon colored, text gray
            Row {
                spacing: 0
                Rectangle {
                    width: dirIcon.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.pink
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: dirIcon; anchors.centerIn: parent; text: ""; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: dirText.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: dirText; anchors.centerIn: parent; text: "jimdots"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // Clock
            Row {
                visible: Config.tmuxShowClock; spacing: 0
                Rectangle {
                    width: clockIcon.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.blue
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: clockIcon; anchors.centerIn: parent; text: "󰃰"; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: clockText.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: clockText; anchors.centerIn: parent; text: "14:30"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // CPU
            Row {
                visible: Config.tmuxShowCpu; spacing: 0
                Rectangle {
                    width: cpuIcon.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.teal
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: cpuIcon; anchors.centerIn: parent; text: ""; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: cpuText.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: cpuText; anchors.centerIn: parent; text: "12%"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // GPU
            Row {
                visible: Config.tmuxShowGpu; spacing: 0
                Rectangle {
                    width: gpuIcon.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.green
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: gpuIcon; anchors.centerIn: parent; text: "󰢮"; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: gpuText.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: gpuText; anchors.centerIn: parent; text: "8%"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }

            // Temp
            Row {
                visible: Config.tmuxShowTemp; spacing: 0
                Rectangle {
                    width: tempIcon.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.yellow
                    Rectangle { anchors.right: parent.right; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: tempIcon; anchors.centerIn: parent; text: ""; color: Config.base; font.pixelSize: 9; font.family: Config.fontFamily }
                }
                Rectangle {
                    width: tempText.implicitWidth + 8; height: 20
                    radius: parent.parent.parent.shapeRadius; color: Config.surface0
                    Rectangle { anchors.left: parent.left; width: parent.radius; height: parent.height; color: parent.color }
                    Text { id: tempText; anchors.centerIn: parent; text: "52°C"; color: Config.text; font.pixelSize: 9; font.family: Config.fontFamily }
                }
            }
        }
    }
}
