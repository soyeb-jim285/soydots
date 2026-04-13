# Notification Icon/Image Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show app icons and notification images in toast popups and notification center history items.

**Architecture:** Replace the urgency icon (toasts) and urgency dot (history) with an icon/image element that resolves from `notification.image` > `notification.appIcon` > urgency fallback. Uses Quickshell's built-in `Quickshell.iconPath()` for freedesktop icon theme lookup.

**Tech Stack:** QML (Quickshell), freedesktop icon themes

**Spec:** `docs/superpowers/specs/2026-04-13-notification-icons-design.md`

---

### Task 1: Add icon data to toast model

**Files:**
- Modify: `quickshell/NotificationPopup.qml:154-174` (addToast function)
- Modify: `quickshell/NotificationPopup.qml:280-288` (toast delegate required properties)

- [ ] **Step 1: Add appIcon and image to the toastModel insert call**

In `quickshell/NotificationPopup.qml`, modify the `addToast` function (line 154). The `notification` parameter already has `.appIcon` and `.image` — pass them into the model:

```qml
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
```

- [ ] **Step 2: Add required properties to the toast delegate**

In the same file, add `appIcon` and `image` required properties to the toast `Rectangle` delegate (after line 288):

```qml
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
```

- [ ] **Step 3: Verify quickshell reloads without errors**

Run: `quickshell msg reload reload` or restart quickshell.
Expected: No QML errors. Toasts still appear as before (icon data is stored but not yet displayed).

- [ ] **Step 4: Commit**

```bash
git add quickshell/NotificationPopup.qml
git commit -m "feat(notif): add appIcon and image data to toast model"
```

---

### Task 2: Replace toast urgency icon with icon/image + fallback

**Files:**
- Modify: `quickshell/NotificationPopup.qml:329-349` (toast Row content — urgency Loader and Column width)

- [ ] **Step 1: Replace the urgency icon Loader with icon/image + fallback**

In `quickshell/NotificationPopup.qml`, replace the `Loader` block (lines 338-346) and update the Column width (line 349) inside the toast `Row`:

Replace this block:
```qml
                    Row {
                        id: toastRow
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 8

                        Loader {
                            id: urgencyIconLoader
                            anchors.verticalCenter: parent.verticalCenter
                            source: root.urgencyIconSource(toast.urgency)
                            onLoaded: {
                                item.size = 14;
                                item.color = Qt.binding(() => root.urgencyColor(toast.urgency));
                            }
                        }

                        Column {
                            width: parent.width - 26
```

With:
```qml
                    Row {
                        id: toastRow
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
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
                                if (toast.appIcon !== "")
                                    return Quickshell.iconPath(toast.appIcon, true);
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
                                visible: !toastIconSlot.toastIconHasImage
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
```

- [ ] **Step 2: Verify toasts display correctly**

Run: `notify-send -a "firefox" "Test" "Icon should appear"` and `notify-send "No Icon" "Should show urgency icon"`.
Expected: First toast shows the Firefox icon in a 32px rounded square. Second toast shows the urgency bell icon as before.

- [ ] **Step 3: Commit**

```bash
git add quickshell/NotificationPopup.qml
git commit -m "feat(notif): show app icon/image in toast popups with urgency fallback"
```

---

### Task 3: Replace notification center urgency dot with icon/image + fallback

**Files:**
- Modify: `quickshell/NotificationCenter.qml:753-790` (history item Row — dot and Column)

- [ ] **Step 1: Replace the urgency dot with icon/image + fallback**

In `quickshell/NotificationCenter.qml`, replace the urgency dot `Rectangle` (lines 763-767) and update the Column width (line 770) inside the history item `Row`:

Replace this block:
```qml
                                // Left side: dot + text content
                                Row {
                                    id: histRow
                                    anchors.left: parent.left
                                    anchors.right: histRight.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6; height: 6; radius: 3
                                        color: root.notifSource.urgencyColor(histItem.modelData.urgency)
                                    }

                                    Column {
                                        width: parent.width - 18
                                        spacing: 1

                                        Text {
                                            text: histItem.modelData.summary || histItem.modelData.appName || "Notification"
                                            color: Theme.text
                                            font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            visible: text !== ""
                                            text: histItem.modelData.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                                            color: Theme.subtext0
                                            font.pixelSize: 10; font.family: Theme.fontFamily
                                            width: parent.width
                                            elide: Text.ElideRight; maximumLineCount: 1
                                        }
                                    }
```

With:
```qml
                                // Left side: icon + text content
                                Row {
                                    id: histRow
                                    anchors.left: parent.left
                                    anchors.right: histRight.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 8

                                    // Icon/image slot with urgency dot fallback
                                    Item {
                                        id: histIconSlot
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: histIconHasImage ? 28 : 6
                                        height: histIconHasImage ? 28 : 6

                                        property string iconSource: {
                                            let md = histItem.modelData;
                                            if ((md.image || "") !== "")
                                                return md.image;
                                            if ((md.appIcon || "") !== "")
                                                return Quickshell.iconPath(md.appIcon, true);
                                            return "";
                                        }
                                        property bool histIconHasImage: iconSource !== ""

                                        // App icon / notification image
                                        Rectangle {
                                            visible: histIconSlot.histIconHasImage
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.crust
                                            border.color: Theme.surface1
                                            border.width: 1
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 1
                                                source: histIconSlot.iconSource
                                                sourceSize.width: 28
                                                sourceSize.height: 28
                                                fillMode: Image.PreserveAspectCrop
                                                smooth: true
                                            }
                                        }

                                        // Urgency dot fallback
                                        Rectangle {
                                            visible: !histIconSlot.histIconHasImage
                                            anchors.centerIn: parent
                                            width: 6; height: 6; radius: 3
                                            color: root.notifSource.urgencyColor(histItem.modelData.urgency)
                                        }
                                    }

                                    Column {
                                        width: parent.width - histIconSlot.width - 8
                                        spacing: 1

                                        Text {
                                            text: histItem.modelData.summary || histItem.modelData.appName || "Notification"
                                            color: Theme.text
                                            font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            visible: text !== ""
                                            text: histItem.modelData.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
                                            color: Theme.subtext0
                                            font.pixelSize: 10; font.family: Theme.fontFamily
                                            width: parent.width
                                            elide: Text.ElideRight; maximumLineCount: 1
                                        }
                                    }
```

- [ ] **Step 2: Verify history items display correctly**

Run: `notify-send -a "telegram-desktop" "Telegram" "New message from Alice"` then open the notification center.
Expected: History item shows the Telegram icon in a 28px rounded square instead of the colored dot. Items without icons still show the urgency dot.

- [ ] **Step 3: Commit**

```bash
git add quickshell/NotificationCenter.qml
git commit -m "feat(notif): show app icon/image in notification center history with urgency fallback"
```

---

### Task 4: End-to-end verification

**Files:** None (testing only)

- [ ] **Step 1: Test icon resolution for common apps**

Send test notifications and verify icons appear:

```bash
# App with desktop entry icon — should show app icon
notify-send -a "firefox" "Firefox" "Page loaded"

# App with custom icon path — should show the icon
notify-send -i "/usr/share/icons/hicolor/48x48/apps/telegram.png" "Telegram" "New message"

# App with no icon — should fall back to urgency dot/icon
notify-send "Plain" "No icon notification"

# Screenshot notification (if hyprshot sends one with image)
# Trigger a screenshot and check the notification shows a preview
```

Expected: Icons appear for apps that provide them, urgency fallback for those that don't.

- [ ] **Step 2: Test image priority over appIcon**

```bash
# Notification with both image and appIcon — image should win
notify-send -a "firefox" -i "/usr/share/icons/hicolor/48x48/apps/telegram.png" "Priority Test" "Image should show telegram icon, not firefox"
```

Expected: The Telegram icon appears (from `-i` flag), not the Firefox icon.

- [ ] **Step 3: Verify both toast and history show the same icon**

Send a notification, see the toast, then open the notification center and verify the same icon appears in the history item.

- [ ] **Step 4: Final commit (if any fixes were needed)**

```bash
git add quickshell/NotificationPopup.qml quickshell/NotificationCenter.qml
git commit -m "fix(notif): polish icon/image display"
```
