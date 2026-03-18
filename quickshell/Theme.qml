pragma Singleton

import QtQuick

QtObject {
    // Catppuccin Mocha palette
    readonly property string base: "#1e1e2e"
    readonly property string mantle: "#181825"
    readonly property string crust: "#11111b"
    readonly property string surface0: "#313244"
    readonly property string surface1: "#45475a"
    readonly property string surface2: "#585b70"
    readonly property string overlay0: "#6c7086"
    readonly property string overlay1: "#7f849c"
    readonly property string text: "#cdd6f4"
    readonly property string subtext0: "#a6adc8"
    readonly property string subtext1: "#bac2de"
    readonly property string red: "#f38ba8"
    readonly property string green: "#a6e3a1"
    readonly property string yellow: "#f9e2af"
    readonly property string blue: "#89b4fa"
    readonly property string mauve: "#cba6f7"
    readonly property string pink: "#f5c2e7"
    readonly property string teal: "#94e2d5"
    readonly property string peach: "#fab387"
    readonly property string lavender: "#b4befe"

    // Font
    readonly property string fontFamily: "Maple Mono"
    readonly property string iconFont: "Maple Mono NF"

    // Bar dimensions
    readonly property int barHeight: 38
    readonly property int barMargin: 6
    readonly property int barRadius: 10
    readonly property int widgetSpacing: 6
    readonly property int widgetPadding: 10
    readonly property int widgetRadius: 8

    // Font sizes
    readonly property int fontSizeSmall: 11
    readonly property int fontSize: 13
    readonly property int fontSizeIcon: 16

    // Animation
    readonly property int animDuration: 200
    readonly property int animDurationFast: 100
}
