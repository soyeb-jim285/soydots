pragma Singleton

import QtQuick

QtObject {
    // Theme transition duration (ms)
    readonly property int themeTransitionDuration: 1000

    // Catppuccin palette — animated color properties for smooth theme transitions
    property color base: Config.base
    Behavior on base { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color mantle: Config.mantle
    Behavior on mantle { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color crust: Config.crust
    Behavior on crust { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color surface0: Config.surface0
    Behavior on surface0 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color surface1: Config.surface1
    Behavior on surface1 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color surface2: Config.surface2
    Behavior on surface2 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color overlay0: Config.overlay0
    Behavior on overlay0 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color overlay1: Config.overlay1
    Behavior on overlay1 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color text: Config.text
    Behavior on text { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color subtext0: Config.subtext0
    Behavior on subtext0 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color subtext1: Config.subtext1
    Behavior on subtext1 { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color red: Config.red
    Behavior on red { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color green: Config.green
    Behavior on green { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color yellow: Config.yellow
    Behavior on yellow { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color blue: Config.blue
    Behavior on blue { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color mauve: Config.mauve
    Behavior on mauve { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color pink: Config.pink
    Behavior on pink { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color teal: Config.teal
    Behavior on teal { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color peach: Config.peach
    Behavior on peach { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }
    property color lavender: Config.lavender
    Behavior on lavender { ColorAnimation { duration: themeTransitionDuration; easing.type: Easing.Bezier; easing.bezierCurve: [0.54,0,0.34,0.99,1,1] } }

    // Font
    readonly property string fontFamily: Config.fontFamily
    readonly property string iconFont: Config.iconFont

    // Bar dimensions
    readonly property int barHeight: Config.barHeight
    readonly property int barMargin: Config.barMargin
    readonly property int barRadius: Config.barRadius
    readonly property int widgetSpacing: Config.widgetSpacing
    readonly property int widgetPadding: Config.widgetPadding
    readonly property int widgetRadius: Config.widgetRadius

    // Font sizes
    readonly property int fontSizeSmall: Config.fontSizeSmall
    readonly property int fontSize: Config.fontSize
    readonly property int fontSizeIcon: Config.fontSizeIcon

    // Animation
    readonly property int animDuration: Config.animDuration
    readonly property int animDurationFast: Config.animDurationFast

    // Transparency helpers
    function _bg(colorVal, opacity) {
        return Qt.rgba(colorVal.r, colorVal.g, colorVal.b, Config.transparencyEnabled ? opacity : 1.0);
    }

    // Global fallback
    readonly property real panelOpacity: Config.transparencyEnabled ? Config.transparencyLevel : 1.0
    readonly property color panelBg: _bg(mantle, panelOpacity)

    // Per-component backgrounds (all use mantle for consistency — same as bar/settings which work)
    readonly property color barBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyBar : 1.0)
    readonly property color launcherBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyLauncher : 1.0)
    readonly property color clipboardBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyClipboard : 1.0)
    readonly property color notifCenterBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyNotifCenter : 1.0)
    readonly property color notifPopupBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyNotifPopup : 1.0)
    readonly property color osdBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyOsd : 1.0)
    readonly property color settingsBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencySettings : 1.0)
    readonly property color animPickerBg: _bg(mantle, Config.transparencyEnabled ? Config.transparencyAnimPicker : 1.0)
}
