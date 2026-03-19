pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property var history: []
    property int unreadCount: 0


    function urgencyIcon(urgency: int): string {
        if (urgency === NotificationUrgency.Critical) return "\uf06a";
        if (urgency === NotificationUrgency.Low) return "\uf05a";
        return "\uf0f3";
    }

    function urgencyColor(urgency: int): string {
        if (urgency === NotificationUrgency.Critical) return Theme.red;
        if (urgency === NotificationUrgency.Low) return Theme.overlay0;
        return Theme.blue;
    }

    NotificationServer {
        id: server
        imageSupported: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true

        onNotification: notification => {
            notification.tracked = true;
            let timeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5000;

            let entry = {
                summary: notification.summary || "",
                body: (notification.body || "").replace(/<[^>]*>/g, "").replace(/\n/g, " "),
                appName: notification.appName || "",
                urgency: notification.urgency,
                time: Date.now(),
                timeout: timeout
            };

            // Add toast popup
            root.addToast(entry, notification);

            // Add to history
            let hist = root.history.slice();
            hist.unshift({
                notif: notification,
                summary: entry.summary,
                body: entry.body,
                appName: entry.appName,
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                urgency: entry.urgency,
                actions: notification.actions,
                time: new Date(),
                timeout: timeout
            });
            if (hist.length > 50) hist.pop();
            root.history = hist;
            root.unreadCount++;
        }
    }

    function dismissToast(index: int) {
        if (index >= 0 && index < toastModel.count)
            removeToastById(toastModel.get(index).toastId);
    }

    function dismissHistory(index: int) {
        let hist = root.history.slice();
        if (index >= 0 && index < hist.length) {
            if (hist[index].notif) hist[index].notif.dismiss();
            hist.splice(index, 1);
            root.history = hist;
        }
    }

    function clearAll() {
        for (let entry of root.history)
            if (entry.notif) entry.notif.dismiss();
        root.history = [];
        toastModel.clear();
        root.unreadCount = 0;
    }

    function resetUnread() { root.unreadCount = 0; }

    function timeAgo(date: var): string {
        let s = Math.floor((new Date() - date) / 1000);
        if (s < 60) return "now";
        let m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        let h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }


    ListModel { id: toastModel }

    // Store notification objects by toast ID for action invocation
    property var toastNotifs: ({})

    property int toastIdCounter: 0
    property int itemHeight: 48
    property int itemSpacing: 6

    function addToast(entry: var, notification: var) {
        let id = toastIdCounter++;
        let hasActions = notification && notification.actions && notification.actions.length > 0;
        // Store notification reference for action invocation
        let n = toastNotifs;
        n[id] = notification;
        toastNotifs = n;

        toastModel.insert(0, {
            toastId: id,
            summary: entry.summary || "",
            body: entry.body || "",
            appName: entry.appName || "",
            urgency: entry.urgency,
            timeout: entry.timeout,
            elapsed: 0,
            hasActions: hasActions
        });
        if (toastModel.count > 3)
            toastModel.remove(toastModel.count - 1);
    }

    function invokeDefaultAction(id: int) {
        let notif = toastNotifs[id];
        if (notif && notif.actions && notif.actions.length > 0) {
            notif.actions[0].invoke();
        }
        removeToastById(id);
    }

    // Track dying toast IDs for exit animation
    property var dyingIds: []

    function isDying(id: int): bool {
        return dyingIds.indexOf(id) >= 0;
    }

    function removeToastById(id: int) {
        // Skip if already dying
        if (isDying(id)) return;
        // Mark as dying
        dyingIds = dyingIds.concat([id]);
    }

    // Delayed removal after animation
    Timer {
        id: removeTimer
        interval: 300
        repeat: true
        running: root.dyingIds.length > 0
        onTriggered: {
            let ids = root.dyingIds.slice();
            for (let id of ids) {
                for (let i = 0; i < toastModel.count; i++) {
                    if (toastModel.get(i).toastId === id) {
                        toastModel.remove(i);
                        break;
                    }
                }
            }
            root.dyingIds = [];
        }
    }

    // Auto-expire toasts — uses the progress bar's remaining value
    // Each toast tracks its own remaining time via its Timer, so we just
    // check which ones should be removed
    Timer {
        interval: 500
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            for (let i = toastModel.count - 1; i >= 0; i--) {
                let item = toastModel.get(i);
                // Don't re-trigger dying toasts
                if (root.isDying(item.toastId)) continue;
                // Use elapsed counter approach — each toast stores creation offset
                if (item.elapsed >= item.timeout)
                    root.removeToastById(item.toastId);
            }
        }
    }

    // Increment elapsed for all toasts
    Timer {
        interval: 100
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            for (let i = 0; i < toastModel.count; i++)
                toastModel.setProperty(i, "elapsed", toastModel.get(i).elapsed + 100);
        }
    }

    LazyLoader {
        id: popupLoader
        active: toastModel.count > 0

        PanelWindow {
            id: popupWindow

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notif"

        anchors { top: true; right: true }
        implicitWidth: 300
        implicitHeight: 250
        exclusiveZone: 0
        color: "transparent"

        margins.top: 0
        margins.right: 8

        Item {
            id: toastContainer
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 6
            width: 280
            height: parent.height

            Repeater {
                model: toastModel

                Rectangle {
                    id: toast
                    required property int index
                    required property int toastId
                    required property string summary
                    required property string body
                    required property string appName
                    required property int urgency
                    required property int timeout
                    required property int elapsed
                    required property bool hasActions

                    width: toastContainer.width
                    height: root.itemHeight
                    radius: 10
                    color: "#cc181825"
                    border.color: urgency === NotificationUrgency.Critical ? Theme.red : Theme.surface1
                    border.width: 1
                    // Progress bar
                    Rectangle {
                        z: 10
                        x: 8
                        y: parent.height - 5
                        width: (parent.width - 16) * Math.max(0, 1 - toast.elapsed / toast.timeout)
                        height: 2
                        radius: 1
                        color: root.urgencyColor(toast.urgency)
                    }

                    // Position based on index, animated smoothly
                    y: index * (root.itemHeight + root.itemSpacing)
                    Behavior on y {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    // Slide in on creation, slide out on dismiss
                    property bool isNew: true
                    property bool isDying: root.isDying(toastId)

                    x: isNew ? 280 : (isDying ? 280 : 0)
                    opacity: isNew ? 0 : (isDying ? 0 : 1)
                    Component.onCompleted: isNew = false
                    Behavior on x {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }


                    Row {
                        id: toastRow
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.urgencyIcon(toast.urgency)
                            color: root.urgencyColor(toast.urgency)
                            font.pixelSize: 14; font.family: Theme.iconFont
                        }

                        Column {
                            width: parent.width - 26
                            spacing: 1

                            Row {
                                width: parent.width; spacing: 4
                                Text {
                                    text: toast.appName ? toast.appName + " \u2022 " : ""
                                    color: Theme.overlay0
                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                    visible: text !== ""
                                }
                                Text {
                                    text: toast.summary
                                    color: Theme.text
                                    font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width - (parent.children[0].visible ? parent.children[0].implicitWidth : 0)
                                }
                            }

                            Text {
                                visible: text !== ""
                                text: toast.body
                                color: Theme.subtext0
                                font.pixelSize: 10; font.family: Theme.fontFamily
                                width: parent.width
                                elide: Text.ElideRight; maximumLineCount: 1
                            }
                        }
                    }

                    Text {
                        id: closeBtn
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.rightMargin: 8; anchors.topMargin: 6
                        text: "\uf00d"
                        color: closeMouse.containsMouse ? Theme.text : Theme.surface2
                        font.pixelSize: 9; font.family: Theme.iconFont
                        Behavior on color { ColorAnimation { duration: 80 } }
                        MouseArea {
                            id: closeMouse; anchors.fill: parent; anchors.margins: -4
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.removeToastById(toast.toastId)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; z: -1
                        cursorShape: toast.hasActions ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (toast.hasActions)
                                root.invokeDefaultAction(toast.toastId);
                            else
                                root.removeToastById(toast.toastId);
                        }
                    }
                }
            }
        }
    }
    }
}
