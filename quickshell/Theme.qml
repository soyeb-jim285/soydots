pragma Singleton

import QtQuick

QtObject {
    // Catppuccin Mocha palette — re-exported from Config
    readonly property string base: Config.base
    readonly property string mantle: Config.mantle
    readonly property string crust: Config.crust
    readonly property string surface0: Config.surface0
    readonly property string surface1: Config.surface1
    readonly property string surface2: Config.surface2
    readonly property string overlay0: Config.overlay0
    readonly property string overlay1: Config.overlay1
    readonly property string text: Config.text
    readonly property string subtext0: Config.subtext0
    readonly property string subtext1: Config.subtext1
    readonly property string red: Config.red
    readonly property string green: Config.green
    readonly property string yellow: Config.yellow
    readonly property string blue: Config.blue
    readonly property string mauve: Config.mauve
    readonly property string pink: Config.pink
    readonly property string teal: Config.teal
    readonly property string peach: Config.peach
    readonly property string lavender: Config.lavender

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
    function _bg(colorStr, opacity) {
        let c = Qt.color(colorStr);
        return Qt.rgba(c.r, c.g, c.b, Config.transparencyEnabled ? opacity : 1.0);
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
