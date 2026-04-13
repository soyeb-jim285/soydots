pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "icons"

Scope {
    id: root

    property var history: []
    property int unreadCount: 0
    property bool dndEnabled: false


    function urgencyIconSource(urgency: int): string {
        if (urgency === NotificationUrgency.Critical) return "icons/IconAlertCircle.qml";
        if (urgency === NotificationUrgency.Low) return "icons/IconInfo.qml";
        return "icons/IconBell.qml";
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
            let timeout = notification.expireTimeout > 0 ? notification.expireTimeout : Config.notifDefaultTimeout;

            let entry = {
                summary: notification.summary || "",
                body: (notification.body || "").replace(/<[^>]*>/g, "").replace(/\n/g, " "),
                appName: notification.appName || "",
                urgency: notification.urgency,
                time: Date.now(),
                timeout: timeout
            };

            // Add toast popup (suppressed in DND mode)
            if (!root.dndEnabled)
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
            if (hist.length > Config.notifMaxHistory) hist.pop();
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

    // Focus app window by searching hyprland clients
    Process {
        id: focusAppProc
        property string appName: ""
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = focusAppProc.appName.toLowerCase();
                try {
                    let clients = JSON.parse(this.text);
                    let match = null;
                    for (let c of clients) {
                        let cls = (c["class"] || "").toLowerCase();
                        let initCls = (c.initialClass || "").toLowerCase();
                        let title = (c.title || "").toLowerCase();
                        if (cls === name || initCls === name) { match = c; break; }
                        if (cls.includes(name) || initCls.includes(name)) { match = c; break; }
                        if (title.includes(name)) { if (!match) match = c; }
                    }
                    if (match) {
                        Hyprland.dispatch("focuswindow address:" + match.address);
                    }
                } catch(e) {}
            }
        }
    }

    function focusApp(appName: string) {
        if (appName !== "") {
            focusAppProc.appName = appName;
            focusAppProc.running = true;
        }
    }

    property int toastIdCounter: 0
    property int itemHeight: Config.notifPopupHeight
    property int itemSpacing: Config.notifPopupSpacing

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
            appIcon: notification ? (notification.appIcon || "") : "",
            image: notification ? (notification.image || "") : "",
            urgency: entry.urgency,
            timeout: entry.timeout,
            elapsed: 0,
            hasActions: hasActions
        });
        if (toastModel.count > Config.notifMaxToasts)
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
        implicitWidth: Config.notifPopupWindowWidth
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
            width: Config.notifPopupWidth
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
                    required property string appIcon
                    required property string image
                    required property int urgency
                    required property int timeout
                    required property int elapsed
                    required property bool hasActions

                    width: toastContainer.width
                    height: toast.hasActions ? toastContent.implicitHeight + 16 : root.itemHeight
                    radius: Config.notifPopupRadius
                    color: Theme.notifPopupBg
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
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.Linear } }
                    }

                    // Position based on index, animated smoothly
                    y: index * (root.itemHeight + root.itemSpacing)
                    Behavior on y {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    // Slide in on creation, slide out on dismiss
                    property bool isNew: true
                    property bool isDying: root.isDying(toastId)

                    x: isNew ? Config.notifPopupWidth : (isDying ? Config.notifPopupWidth : 0)
                    opacity: isNew ? 0 : (isDying ? 0 : 1)
                    Component.onCompleted: isNew = false
                    Behavior on x {
                        NumberAnimation { duration: Config.animPopupSlideDuration; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Config.animPopupFadeDuration; easing.type: Easing.OutCubic }
                    }


                    Column {
                        id: toastContent
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 6

                        Row {
                            id: toastRow
                            width: parent.width
                            spacing: 8

                            // Icon/image slot with urgency fallback
                            Item {
                                id: toastIconSlot
                                anchors.verticalCenter: parent.verticalCenter
                                width: toastIconHasImage ? 32 : 14
                                height: toastIconHasImage ? 32 : 14

                                property string iconSource: {
                                    if (toast.image !== "")
                                        return toast.image;
                                    let icon = toast.appIcon || toast.appName;
                                    if (icon !== "") {
                                        if (icon.startsWith("/") || icon.startsWith("file://"))
                                            return icon;
                                        return Quickshell.iconPath(icon, true);
                                    }
                                    return "";
                                }
                                property bool toastIconHasImage: iconSource !== ""

                                // App icon / notification image
                                Rectangle {
                                    visible: toastIconSlot.toastIconHasImage
                                    anchors.fill: parent
                                    radius: 8
                                    color: Theme.crust
                                    border.color: Theme.surface1
                                    border.width: 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: toastIconSlot.iconSource
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                    }
                                }

                                // Urgency icon fallback
                                Loader {
                                    active: !toastIconSlot.toastIconHasImage
                                    visible: active
                                    anchors.centerIn: parent
                                    source: root.urgencyIconSource(toast.urgency)
                                    onLoaded: {
                                        item.size = 14;
                                        item.color = Qt.binding(() => root.urgencyColor(toast.urgency));
                                    }
                                }
                            }

                            Column {
                                width: parent.width - toastIconSlot.width - 8
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

                        // Action buttons
                        Row {
                            visible: toast.hasActions
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: {
                                    let notif = root.toastNotifs[toast.toastId];
                                    if (!notif || !notif.actions) return [];
                                    let acts = [];
                                    for (let i = 0; i < Math.min(notif.actions.length, 3); i++)
                                        acts.push({ text: notif.actions[i].text, idx: i });
                                    return acts;
                                }

                                Rectangle {
                                    required property var modelData
                                    width: (parent.width - (parent.children.length - 1) * 6) / parent.children.length
                                    height: 24
                                    radius: 6
                                    color: actionMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: actionMouse.containsMouse ? Theme.text : Theme.subtext0
                                        font.pixelSize: 10; font.family: Theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let notif = root.toastNotifs[toast.toastId];
                                            if (notif && notif.actions && notif.actions.length > modelData.idx)
                                                notif.actions[modelData.idx].invoke();
                                            root.removeToastById(toast.toastId);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    IconX {
                        id: closeBtn
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.rightMargin: 8; anchors.topMargin: 6
                        size: 9
                        color: closeMouse.containsMouse ? Theme.text : Theme.surface2
                        Behavior on color { ColorAnimation { duration: 80 } }
                        MouseArea {
                            id: closeMouse; anchors.fill: parent; anchors.margins: -4
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.removeToastById(toast.toastId)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (toast.hasActions)
                                root.invokeDefaultAction(toast.toastId);
                            else
                                root.removeToastById(toast.toastId);
                            root.focusApp(toast.appName);
                        }
                    }
                }
            }
        }
    }
    }
}
