import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

ColumnLayout {
    spacing: 6

    // Dark Mode Toggle
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 12

        Text {
            text: "Dark Mode"
            color: Config.text
            font.pixelSize: 14; font.family: Config.fontFamily; font.bold: true
        }

        Item { Layout.fillWidth: true }

        ToggleSetting {
            label: ""
            section: "appearance"
            key: "darkMode"
            value: Config.darkMode
            onValueChanged: {
                if (value !== Config.darkMode)
                    Config.toggleDarkMode();
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Config.surface1
        Layout.bottomMargin: 8
    }

    // Theme Presets
    Text {
        text: "Theme Presets"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.bottomMargin: 4
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [
                { name: "Mocha", base: "#1e1e2e", mantle: "#181825", crust: "#11111b", surface0: "#313244", surface1: "#45475a", surface2: "#585b70", overlay0: "#6c7086", overlay1: "#7f849c", text: "#cdd6f4", subtext0: "#a6adc8", subtext1: "#bac2de", red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af", blue: "#89b4fa", mauve: "#cba6f7", pink: "#f5c2e7", teal: "#94e2d5", peach: "#fab387", lavender: "#b4befe" },
                { name: "Macchiato", base: "#24273a", mantle: "#1e2030", crust: "#181926", surface0: "#363a4f", surface1: "#494d64", surface2: "#5b6078", overlay0: "#6e738d", overlay1: "#8087a2", text: "#cad3f5", subtext0: "#a5adcb", subtext1: "#b8c0e0", red: "#ed8796", green: "#a6da95", yellow: "#eed49f", blue: "#8aadf4", mauve: "#c6a0f6", pink: "#f5bde6", teal: "#8bd5ca", peach: "#f5a97f", lavender: "#b7bdf8" },
                { name: "Frappe", base: "#303446", mantle: "#292c3c", crust: "#232634", surface0: "#414559", surface1: "#51576d", surface2: "#626880", overlay0: "#737994", overlay1: "#838ba7", text: "#c6d0f5", subtext0: "#a5adce", subtext1: "#b5bfe2", red: "#e78284", green: "#a6d189", yellow: "#e5c890", blue: "#8caaee", mauve: "#ca9ee6", pink: "#f4b8e4", teal: "#81c8be", peach: "#ef9f76", lavender: "#babbf1" },
                { name: "Latte", base: "#eff1f5", mantle: "#e6e9ef", crust: "#dce0e8", surface0: "#ccd0da", surface1: "#bcc0cc", surface2: "#acb0be", overlay0: "#9ca0b0", overlay1: "#8c8fa1", text: "#4c4f69", subtext0: "#6c6f85", subtext1: "#5c5f77", red: "#d20f39", green: "#40a02b", yellow: "#df8e1d", blue: "#1e66f5", mauve: "#8839ef", pink: "#ea76cb", teal: "#179299", peach: "#fe640b", lavender: "#7287fd" }
            ]

            Rectangle {
                required property var modelData
                required property int index
                width: 120; height: 36; radius: 8
                color: presetMouse.containsMouse ? Config.surface0 : "transparent"
                border.color: Config.base === modelData.base ? Config.blue : "transparent"
                border.width: Config.base === modelData.base ? 1 : 0
                Behavior on color { ColorAnimation { duration: 80 } }

                Row {
                    anchors.centerIn: parent; spacing: 6
                    // Mini color preview
                    Row {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle { width: 10; height: 10; radius: 2; color: modelData.blue }
                        Rectangle { width: 10; height: 10; radius: 2; color: modelData.green }
                        Rectangle { width: 10; height: 10; radius: 2; color: modelData.red }
                    }
                    Text {
                        text: modelData.name
                        color: Config.text
                        font.pixelSize: 11; font.family: Config.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: presetMouse
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let colors = ["base", "mantle", "crust", "surface0", "surface1", "surface2",
                                      "overlay0", "overlay1", "text", "subtext0", "subtext1",
                                      "red", "green", "yellow", "blue", "mauve", "pink", "teal", "peach", "lavender"];
                        for (let c of colors)
                            Config.set("appearance", c, modelData[c]);
                    }
                }
            }
        }
    }

    // Transparency
    Text {
        text: "Transparency"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.topMargin: 12; Layout.bottomMargin: 4
    }

    ToggleSetting { label: "Enable Transparency"; section: "appearance"; key: "transparencyEnabled"; value: Config.transparencyEnabled }

    Text {
        text: "Blur is applied automatically via Hyprland layer rules when transparency is enabled."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
        visible: Config.transparencyEnabled
    }

    SliderSetting {
        label: "Global Opacity"
        section: "appearance"; key: "transparencyLevel"
        value: Config.transparencyLevel
        from: 0.1; to: 1.0; decimals: 2; stepSize: 0.05
        visible: Config.transparencyEnabled
    }

    Text {
        text: "Per-Component Opacity"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.topMargin: 8; Layout.bottomMargin: 2
        visible: Config.transparencyEnabled
    }

    Text {
        text: "Set to -1 to use global opacity. Values 0.1\u20131.0 override per component."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
        visible: Config.transparencyEnabled
    }

    SliderSetting { label: "Status Bar"; section: "transparency"; key: "bar"; value: Config._data?.transparency?.bar ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "App Launcher"; section: "transparency"; key: "launcher"; value: Config._data?.transparency?.launcher ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "Clipboard"; section: "transparency"; key: "clipboard"; value: Config._data?.transparency?.clipboard ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "Notif Center"; section: "transparency"; key: "notifCenter"; value: Config._data?.transparency?.notifCenter ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "Notif Popup"; section: "transparency"; key: "notifPopup"; value: Config._data?.transparency?.notifPopup ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "OSD"; section: "transparency"; key: "osd"; value: Config._data?.transparency?.osd ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "Settings"; section: "transparency"; key: "settings"; value: Config._data?.transparency?.settings ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
    SliderSetting { label: "Anim Picker"; section: "transparency"; key: "animPicker"; value: Config._data?.transparency?.animPicker ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }

    // Base Colors
    Text {
        text: "Base Colors"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.topMargin: 12; Layout.bottomMargin: 4
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        rowSpacing: 6

        Repeater {
            model: [
                { label: "Base", key: "base", color: Config.base },
                { label: "Mantle", key: "mantle", color: Config.mantle },
                { label: "Crust", key: "crust", color: Config.crust },
                { label: "Surface 0", key: "surface0", color: Config.surface0 },
                { label: "Surface 1", key: "surface1", color: Config.surface1 },
                { label: "Surface 2", key: "surface2", color: Config.surface2 },
                { label: "Overlay 0", key: "overlay0", color: Config.overlay0 },
                { label: "Overlay 1", key: "overlay1", color: Config.overlay1 },
                { label: "Text", key: "text", color: Config.text },
                { label: "Subtext 0", key: "subtext0", color: Config.subtext0 },
                { label: "Subtext 1", key: "subtext1", color: Config.subtext1 }
            ]

            RowLayout {
                required property var modelData
                spacing: 6

                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: modelData.color
                    border.color: Config.surface1; border.width: 1

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            hexInput.colorKey = modelData.key;
                            hexInput.text = modelData.color;
                            hexInput.forceActiveFocus();
                        }
                    }
                }
                Text {
                    text: modelData.label
                    color: Config.subtext0
                    font.pixelSize: 10; font.family: Config.fontFamily
                }
            }
        }
    }

    // Accent Colors
    Text {
        text: "Accent Colors"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.topMargin: 12; Layout.bottomMargin: 4
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        rowSpacing: 6

        Repeater {
            model: [
                { label: "Red", key: "red", color: Config.red },
                { label: "Green", key: "green", color: Config.green },
                { label: "Yellow", key: "yellow", color: Config.yellow },
                { label: "Blue", key: "blue", color: Config.blue },
                { label: "Mauve", key: "mauve", color: Config.mauve },
                { label: "Pink", key: "pink", color: Config.pink },
                { label: "Teal", key: "teal", color: Config.teal },
                { label: "Peach", key: "peach", color: Config.peach },
                { label: "Lavender", key: "lavender", color: Config.lavender }
            ]

            RowLayout {
                required property var modelData
                spacing: 6

                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: modelData.color
                    border.color: Config.surface1; border.width: 1

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            hexInput.colorKey = modelData.key;
                            hexInput.text = modelData.color;
                            hexInput.forceActiveFocus();
                        }
                    }
                }
                Text {
                    text: modelData.label
                    color: Config.subtext0
                    font.pixelSize: 10; font.family: Config.fontFamily
                }
            }
        }
    }

    // Hex color editor
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 8

        Text {
            text: "Edit Color"
            color: Config.subtext0
            font.pixelSize: 11; font.family: Config.fontFamily
        }

        Quill.TextField {
            id: hexInput
            property string colorKey: ""
            Layout.preferredWidth: 120
            variant: "default"
            placeholder: "#hexcolor"
            onSubmitted: (val) => {
                if (colorKey !== "" && val.match(/^#[0-9a-fA-F]{6}$/))
                    Config.set("appearance", colorKey, val.toLowerCase());
            }
        }

        Rectangle {
            width: 24; height: 24; radius: 4
            color: hexInput.text.match(/^#[0-9a-fA-F]{6}$/) ? hexInput.text : "#000000"
            border.color: Config.surface1; border.width: 1
        }

        Text {
            text: hexInput.colorKey || "click a swatch"
            color: Config.overlay0
            font.pixelSize: 10; font.family: Config.fontFamily
        }
    }

    // Fonts
    Text {
        text: "Fonts"
        color: Config.blue
        font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true
        Layout.topMargin: 16; Layout.bottomMargin: 4
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 12
        Text { text: "Font Family"; color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily; Layout.preferredWidth: 140 }
        Quill.TextField {
            Layout.fillWidth: true
            variant: "filled"
            text: Config.fontFamily
            placeholder: "Font family..."
            onSubmitted: (val) => Config.set("appearance", "fontFamily", val)
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 12
        Text { text: "Icon Font"; color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily; Layout.preferredWidth: 140 }
        Quill.TextField {
            Layout.fillWidth: true
            variant: "filled"
            text: Config.iconFont
            placeholder: "Icon font..."
            onSubmitted: (val) => Config.set("appearance", "iconFont", val)
        }
    }

    SliderSetting {
        label: "Small Font Size"; section: "appearance"; key: "fontSizeSmall"
        value: Config.fontSizeSmall; from: 6; to: 26; stepSize: 1
    }

    SliderSetting {
        label: "Regular Font Size"; section: "appearance"; key: "fontSize"
        value: Config.fontSize; from: 6; to: 26; stepSize: 1
    }

    SliderSetting {
        label: "Icon Font Size"; section: "appearance"; key: "fontSizeIcon"
        value: Config.fontSizeIcon; from: 6; to: 26; stepSize: 1
    }
}
