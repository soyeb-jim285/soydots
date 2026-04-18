import Quickshell
import Quickshell.Io
import QtQuick
import "quill" as Quill

ShellRoot {
    // Bridge the animated shell palette into Quill so both update in lockstep.
    Component.onCompleted: {
        Quill.Theme.background = Qt.binding(() => Theme.base)
        Quill.Theme.backgroundAlt = Qt.binding(() => Theme.mantle)
        Quill.Theme.backgroundDeep = Qt.binding(() => Theme.crust)
        Quill.Theme.surface0 = Qt.binding(() => Theme.surface0)
        Quill.Theme.surface1 = Qt.binding(() => Theme.surface1)
        Quill.Theme.surface2 = Qt.binding(() => Theme.surface2)
        Quill.Theme.overlay0 = Qt.binding(() => Theme.overlay0)
        Quill.Theme.overlay1 = Qt.binding(() => Theme.overlay1)
        Quill.Theme.textPrimary = Qt.binding(() => Theme.text)
        Quill.Theme.textSecondary = Qt.binding(() => Theme.subtext1)
        Quill.Theme.textTertiary = Qt.binding(() => Theme.subtext0)
        Quill.Theme.primary = Qt.binding(() => Theme.blue)
        Quill.Theme.secondary = Qt.binding(() => Theme.lavender)
        Quill.Theme.accent = Qt.binding(() => Theme.mauve)
        Quill.Theme.success = Qt.binding(() => Theme.green)
        Quill.Theme.warning = Qt.binding(() => Theme.yellow)
        Quill.Theme.error = Qt.binding(() => Theme.red)
        Quill.Theme.info = Qt.binding(() => Theme.teal)
        Quill.Theme.fontFamily = Qt.binding(() => Config.fontFamily)
        Quill.Theme.iconFont = Qt.binding(() => Config.iconFont)
        Quill.Theme.fontSizeSmall = Qt.binding(() => Config.fontSizeSmall)
        Quill.Theme.fontSize = Qt.binding(() => Config.fontSize)
        Quill.Theme.animDuration = Qt.binding(() => Config.animDuration)
        Quill.Theme.animDurationFast = Qt.binding(() => Config.animDurationFast)
        Quill.Theme.transparencyEnabled = Qt.binding(() => Config.transparencyEnabled)
        Quill.Theme.transparencyLevel = Qt.binding(() => Config.transparencyLevel)
    }

    IpcHandler {
        target: "theme"
        function toggle(): void {
            Config.toggleDarkMode();
        }
    }

    AppLauncher {}
    StatusBar { notifUnreadCount: notifs.unreadCount; dndEnabled: notifCenter.dndEnabled }
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
