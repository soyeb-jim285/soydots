import Quickshell
import QtQuick
import "quill" as Quill

ShellRoot {
    // Bridge Config → Quill Theme so showcase respects Settings panel
    Component.onCompleted: {
        Quill.Theme.background = Qt.binding(() => Config.base)
        Quill.Theme.backgroundAlt = Qt.binding(() => Config.mantle)
        Quill.Theme.backgroundDeep = Qt.binding(() => Config.crust)
        Quill.Theme.surface0 = Qt.binding(() => Config.surface0)
        Quill.Theme.surface1 = Qt.binding(() => Config.surface1)
        Quill.Theme.surface2 = Qt.binding(() => Config.surface2)
        Quill.Theme.overlay0 = Qt.binding(() => Config.overlay0)
        Quill.Theme.overlay1 = Qt.binding(() => Config.overlay1)
        Quill.Theme.textPrimary = Qt.binding(() => Config.text)
        Quill.Theme.textSecondary = Qt.binding(() => Config.subtext1)
        Quill.Theme.textTertiary = Qt.binding(() => Config.subtext0)
        Quill.Theme.primary = Qt.binding(() => Config.blue)
        Quill.Theme.secondary = Qt.binding(() => Config.lavender)
        Quill.Theme.accent = Qt.binding(() => Config.mauve)
        Quill.Theme.success = Qt.binding(() => Config.green)
        Quill.Theme.warning = Qt.binding(() => Config.yellow)
        Quill.Theme.error = Qt.binding(() => Config.red)
        Quill.Theme.info = Qt.binding(() => Config.teal)
        Quill.Theme.fontFamily = Qt.binding(() => Config.fontFamily)
        Quill.Theme.iconFont = Qt.binding(() => Config.iconFont)
        Quill.Theme.fontSizeSmall = Qt.binding(() => Config.fontSizeSmall)
        Quill.Theme.fontSize = Qt.binding(() => Config.fontSize)
        Quill.Theme.animDuration = Qt.binding(() => Config.animDuration)
        Quill.Theme.animDurationFast = Qt.binding(() => Config.animDurationFast)
        Quill.Theme.transparencyEnabled = Qt.binding(() => Config.transparencyEnabled)
        Quill.Theme.transparencyLevel = Qt.binding(() => Config.transparencyLevel)
    }

    AppLauncher {}
    StatusBar { notifUnreadCount: notifs.unreadCount; dndEnabled: notifCenter.dndEnabled }
    ClipboardHistory {}
    OSD {}
    NotificationPopup { id: notifs; dndEnabled: notifCenter.dndEnabled }
    NotificationCenter { id: notifCenter; notifSource: notifs }
    AnimationPicker {}
    Settings {}
    PowerMenu {}
    LockScreen { id: lockScreen }
    IdleManager { caffeineActive: notifCenter.caffeineEnabled }
    Quill.Showcase {}
}
