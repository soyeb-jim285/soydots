import Quickshell
import QtQuick

ShellRoot {
    AppLauncher {}
    StatusBar { notifUnreadCount: notifs.unreadCount }
    ClipboardHistory {}
    OSD {}
    NotificationPopup { id: notifs }
    NotificationCenter { notifSource: notifs }
}
