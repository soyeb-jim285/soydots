import Quickshell
import QtQuick

ShellRoot {
    AppLauncher {}
    StatusBar { notifUnreadCount: notifs.unreadCount }
    ClipboardHistory {}
    OSD {}
    NotificationPopup { id: notifs; dndEnabled: notifCenter.dndEnabled }
    NotificationCenter { id: notifCenter; notifSource: notifs }
    AnimationPicker {}
    Settings {}
    PowerMenu {}
    LockScreen { id: lockScreen }
}
